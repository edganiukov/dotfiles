#!/usr/bin/env bash

# Lists every coding agent running on the tmux server and switches to the one
# you pick. Bound to a key by agents.tmux, run inside a tmux popup.
#
# Agents are panes running one of @agents-commands, plus any pane that has
# published an @agent_state. State names follow the indicator in the status
# line: wait/done/busy, shown here as blocked/done/working, with panes that run
# an agent but have published nothing counted as idle.

get_tmux_option() {
  local option=$1
  local default_value=$2
  local option_value="$(tmux show-option -gqv "$option")"
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

readonly commands="$(get_tmux_option "@agents-commands" "claude|pi")"
# Unit separator, not a tab: IFS treats tabs as whitespace and would collapse
# the empty fields that panes without an agent session leave behind.
readonly sep=$'\x1f'
readonly esc=$'\033'
readonly reset="${esc}[0m"

# Sorted on: loudest state first, so whatever needs you is always on top.
rank() {
  case $1 in
    wait) echo 0 ;;
    done) echo 1 ;;
    busy) echo 2 ;;
    *) echo 3 ;;
  esac
}

icon() {
  case $1 in
    wait) printf '%s!%s' "${esc}[1;38;5;208m" "$reset" ;;
    done) printf '%s●%s' "${esc}[38;5;142m" "$reset" ;;
    busy) printf '%s○%s' "${esc}[38;5;241m" "$reset" ;;
    *) printf ' ' ;;
  esac
}

label() {
  case $1 in
    wait) echo blocked ;;
    done) echo done ;;
    busy) echo working ;;
    *) echo idle ;;
  esac
}

# claude-code writes its session title into the transcript some turns in, and
# /rename overrides it, so read the newest of each from the end of the log.
transcript_title() {
  local file=$1 line
  [ -f "$file" ] && type jq >/dev/null 2>&1 || return 0

  line="$(tac "$file" 2>/dev/null | grep -m1 '"type":"custom-title"')"
  [ -z "$line" ] && line="$(tac "$file" 2>/dev/null | grep -m1 '"type":"ai-title"')"
  [ -n "$line" ] && printf '%s' "$line" | jq -r '.customTitle // .aiTitle // empty' 2>/dev/null
}

truncate_to() {
  local text=$1 width=$2
  if [ "${#text}" -gt "$width" ]; then
    printf '%s…' "${text:0:width-1}"
  else
    printf '%s' "$text"
  fi
}

# rank <tab> pane_id <tab> display, so fzf can show column 3 and we keep the id.
agents() {
  local fmt="#{pane_id}${sep}#{session_name}${sep}#{window_index}${sep}#{pane_index}"
  fmt="${fmt}${sep}#{pane_current_command}${sep}#{pane_current_path}${sep}#{@agent_state}"
  fmt="${fmt}${sep}#{@agent_session}${sep}#{@agent_transcript}"

  local pane sess widx pidx cmd path state agent_session transcript title
  while IFS="$sep" read -r pane sess widx pidx cmd path state agent_session transcript; do
    [[ $cmd =~ ^(${commands})$ || -n $state ]] || continue

    # pi labels its pane directly; claude-code only records where to look.
    title="$agent_session"
    [ -z "$title" ] && [ -n "$transcript" ] && title="$(transcript_title "$transcript")"

    printf '%s%s%s%s%s %-7s %-8s %-5s %-12s %-8s %s\n' \
      "$(rank "$state")" "$sep" "$pane" "$sep" \
      "$(icon "$state")" "$cmd" "$sess" "$widx.$pidx" \
      "$(truncate_to "${path##*/}" 12)" "$(label "$state")" "$(truncate_to "$title" 28)"
  done < <(tmux list-panes -a -F "$fmt")
}

readonly rows="$(agents | sort -t"$sep" -k1,1n -k3,3)"

if [ -z "$rows" ]; then
  tmux display-message "agents: no agents running"
  exit 0
fi

selected="$(
  printf '%s\n' "$rows" | fzf \
    --ansi \
    --delimiter="$sep" \
    --with-nth=3 \
    --no-sort \
    --reverse \
    --info=inline-right \
    --prompt='agents > ' \
    --header='enter jump   esc close'
)"

[ -n "$selected" ] || exit 0

pane="$(printf '%s' "$selected" | cut -d"$sep" -f2)"
read -r session window < <(tmux display-message -p -t "$pane" "#{session_name}${sep}#{window_id}" | tr "$sep" ' ')

tmux switch-client -t "$session"
tmux select-window -t "$window"
tmux select-pane -t "$pane"
