#!/usr/bin/env bash

# Lists pi panes on the tmux server and switches to the one you pick, or
# creates a session. Bound by agents.tmux; the popup starts in the invoking
# pane's directory so new sessions use that repository.
#
# pi may run as node, so also recognize the @agent_name its extension publishes.
# State names follow the status line: wait/done/busy, shown here as
# blocked/done/working, with panes that have published nothing counted as idle.

readonly plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    wait) printf '%s▲%s' "${esc}[1;38;5;208m" "$reset" ;;
    done) printf '%s✓%s' "${esc}[38;5;142m" "$reset" ;;
    busy) printf '%s●%s' "${esc}[38;5;241m" "$reset" ;;
    *) printf '○' ;;
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

truncate_to() {
  local text=$1 width=$2
  if [ "${#text}" -gt "$width" ]; then
    printf '%s…' "${text:0:width-1}"
  else
    printf '%s' "$text"
  fi
}

# rank <sep> pane_id <sep> display, so fzf can show column 3 and we keep the id.
agents() {
  local fmt="#{pane_id}${sep}#{session_name}${sep}#{window_index}${sep}#{pane_index}"
  fmt="${fmt}${sep}#{pane_current_command}${sep}#{pane_current_path}${sep}#{@agent_state}"
  fmt="${fmt}${sep}#{@agent_session}${sep}#{@agent_name}"

  local pane sess widx pidx cmd path state title name
  while IFS="$sep" read -r pane sess widx pidx cmd path state title name; do
    [[ $cmd = pi || $name = pi ]] || continue

    printf '%s%s%s%s%s %-7s %-8s %-5s %-12s %-8s %s\n' \
      "$(rank "$state")" "$sep" "$pane" "$sep" \
      "$(icon "$state")" "pi" "$sess" "$widx.$pidx" \
      "$(truncate_to "${path##*/}" 16)" "$(label "$state")" "$(truncate_to "$title" 50)"
  done < <(tmux list-panes -a -F "$fmt")
}

readonly rows="$(agents | sort -t"$sep" -k1,1n -k3,3)"

selected="$(
  {
    [ -z "$rows" ] || printf '%s\n' "$rows"
    printf '4%snew%s+ New pi session\n' "$sep" "$sep"
  } | fzf \
    --ansi \
    --delimiter="$sep" \
    --with-nth=3 \
    --no-sort \
    --reverse \
    --info=inline-right \
    --prompt='agents > '
)"

[ -n "$selected" ] || exit 0

pane="$(printf '%s' "$selected" | cut -d"$sep" -f2)"
if [ "$pane" = new ]; then
  "$plugin_dir/agents-new.sh"
  status=$?
  # Keep Git/tmux errors visible rather than closing the popup immediately.
  [ "$status" -eq 0 ] || read -r -p "Press Enter to close. "
  exit "$status"
fi

read -r session window < <(tmux display-message -p -t "$pane" "#{session_name}${sep}#{window_id}" | tr "$sep" ' ')

tmux switch-client -t "$session"
tmux select-window -t "$window"
tmux select-pane -t "$pane"
