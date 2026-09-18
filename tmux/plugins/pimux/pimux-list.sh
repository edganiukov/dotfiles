#!/usr/bin/env bash

# Lists live pi panes and stopped managed workspaces. Bound by pimux.tmux;
# the popup starts in the invoking pane's directory for new sessions.
#
# pi may run as node, so also recognize the @agent_name its extension publishes.
# State names follow the status line: wait/done/busy, shown here as
# blocked/done/working, with panes that have published nothing counted as idle.

readonly plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$plugin_dir/pimux-common.sh"
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
    wait) printf '%s◆%s' "${esc}[1;38;5;167m" "$reset" ;;
    done) printf '%s✤%s' "${esc}[38;5;142m" "$reset" ;;
    busy) printf '%s◌%s' "${esc}[38;5;214m" "$reset" ;;
    *) printf '%s▢%s' "${esc}[38;5;142m" "$reset" ;;
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

# The project a directory belongs to. A managed worktree lives at
# <main>-worktrees/<name>, and its basename is the session name again, which
# said nothing; the main repo's name is what distinguishes rows.
project_of() {
  local dir=$1
  if [[ $dir =~ ^(.*)-worktrees/[^/]+(/.*)?$ ]]; then
    dir="${BASH_REMATCH[1]}"
  else
    dir="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || dir=$1
  fi
  printf '%s' "${dir##*/}"
}

# rank <sep> id <sep> display, so fzf can show column 3 and we keep the id.
# Columns: state, tmux session, window.pane, project, status, then pi's own
# session name only when it differs from the tmux session. Managed sessions
# use one name for the branch, worktree, tmux session and pi session, so
# repeating it across columns just made every row look the same.
# How long since the agent's state last changed, from the @agent_since stamp
# the extension sets alongside @agent_state. "done 40m" is time it has been
# waiting on you; tmux's own activity clock would tick on pi's spinner.
age() {
  local since=$1 secs
  [ -n "$since" ] || return 0
  secs=$(( $(date +%s) - since ))
  if [ "$secs" -lt 60 ]; then printf '%ds' "$secs"
  elif [ "$secs" -lt 3600 ]; then printf '%dm' "$((secs / 60))"
  elif [ "$secs" -lt 86400 ]; then printf '%dh' "$((secs / 3600))"
  else printf '%dd' "$((secs / 86400))"
  fi
}

# The question a blocked agent is waiting on. While a prompt is up, pi swaps
# its editor box for the prompt widget, so the question sits inside the box
# bordered by the bottom two rule lines: the question first, then the
# choices, then a line of key hints. Below the lower rule is only the footer
# (path, tokens, model). So: the first non-empty line between those rules.
last_said() {
  tmux capture-pane -p -t "$1" 2>/dev/null | tac | awk '
    /──/ { rules++; next }
    rules == 1 && NF { sub(/^[[:space:]]+/, ""); last = $0 }
    rules == 2 { exit }
    END { if (last != "") print last }
  '
}

row() {
  local rank=$1 id=$2 icon=$3 sess=$4 where=$5 project=$6 status=$7 age=$8 title=$9
  [ "$title" != "$sess" ] || title=""
  printf '%s%s%s%s%s %-12s %-5s %-14s %-8s %4s  %s\n' \
    "$rank" "$sep" "$id" "$sep" \
    "$icon" "$(truncate_to "$sess" 12)" "$where" "$(truncate_to "$project" 14)" \
    "$status" "$age" "$(truncate_to "$title" 40)"
}

agents() {
  local fmt="#{pane_id}${sep}#{session_name}${sep}#{window_index}${sep}#{pane_index}"
  fmt="${fmt}${sep}#{pane_current_path}${sep}#{@agent_state}${sep}#{@agent_since}"
  fmt="${fmt}${sep}#{@agent_session}${sep}$pi_pane"

  local pane sess widx pidx path state since title is_pi said
  while IFS="$sep" read -r pane sess widx pidx path state since title is_pi; do
    [ "$is_pi" = 1 ] || continue
    # A blocked agent's last line is the question it is waiting on, which is
    # what you need to decide whether to go there; show that over the name.
    if [ "$state" = wait ]; then
      said="$(last_said "$pane")"
      [ -z "$said" ] || title="$said"
    fi
    row "$(rank "$state")" "$pane" "$(icon "$state")" "$sess" "$widx.$pidx" \
      "$(project_of "$path")" "$(label "$state")" "$(age "$since")" "$title"
  done < <(tmux list-panes -a -F "$fmt")
}

# Git is the registry: include the invoking repository and repositories open
# in tmux. The conventional path and matching branch also find older workspaces.
stopped_workspaces() {
  local main field path branch cwd active running
  running="$(tmux list-panes -a -F "#{?$pi_pane,#{pane_current_path},}")"
  while IFS= read -r main; do
    path="" branch=""
    while IFS= read -r -d '' field; do
      case "$field" in
        'worktree '*) path="${field#worktree }" ;;
        'branch refs/heads/'*) branch="${field#branch refs/heads/}" ;;
        '')
          if [[ $branch =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ && $path = "$main-worktrees/$branch" && -d $path ]]; then
            active=false
            while IFS= read -r cwd; do
              [[ $cwd != "$path" && $cwd != "$path/"* ]] || active=true
            done <<< "$running"
            if [ "$active" = false ]; then
              row 4 "$path" "$(icon stopped)" "$branch" - "${main##*/}" stopped "" ""
            fi
          fi
          path="" branch=""
          ;;
      esac
    done < <(git -C "$main" worktree list --porcelain -z)
  done < <(
    {
      printf '%s\n' "$PWD"
      tmux list-panes -a -F '#{pane_current_path}'
    } | sort -u | while IFS= read -r cwd; do
      main="$(main_worktree "$cwd")" && printf '%s\n' "$main"
    done | sort -u
  )
}

rows() {
  { agents; stopped_workspaces; } | sort -t"$sep" -k1,1n -k3,3
}

# Internal listing/refresh modes never start a TUI or run session actions.
if [ "${1:-}" = --rows ]; then
  rows
  exit
fi

if [ "${1:-}" = --refresh ]; then
  [ -f "${PIMUX_ROWS_FILE:-}" ] || exit 1
  next="$(mktemp "${PIMUX_ROWS_FILE}.XXXXXXXX")" || exit 1
  trap 'rm -f -- "$next"' EXIT
  rows > "$next" || exit 1
  if ! cmp -s "$PIMUX_ROWS_FILE" "$next"; then
    mv -- "$next" "$PIMUX_ROWS_FILE" || exit 1
    printf 'reload-sync(cat "$PIMUX_ROWS_FILE")\n'
  fi
  exit 0
fi

# Poll without putting fzf into its loading state. Reload only changed snapshots,
# and feed the completed file so selection tracking never waits on Git/tmux.
cache_dir="$(mktemp -d "${TMPDIR:-/tmp}/pimux-list.XXXXXXXX")" || exit 1
export PIMUX_ROWS_FILE="$cache_dir/rows"
trap 'rm -rf -- "$cache_dir"' EXIT
rows > "$PIMUX_ROWS_FILE" || exit 1

selected="$(
  fzf \
    --ansi \
    --delimiter="$sep" \
    --with-nth=3 \
    --no-sort \
    --reverse \
    --info=inline-right \
    --track --id-nth=2 \
    --bind="every(1),ctrl-r:bg-transform(\"$plugin_dir/pimux-list.sh\" --refresh)" \
    --expect=ctrl-n,ctrl-o,ctrl-x,ctrl-d \
    --footer='enter jump/resume | ctrl-n new | ctrl-o shell | ctrl-x stop | ctrl-d remove' \
    --prompt='pimux > ' < "$PIMUX_ROWS_FILE"
)"
fzf_status=$?
# Clean up before running an action, including Esc back from the name prompt.
rm -rf -- "$cache_dir"
trap - EXIT
# An expected key with no matching row returns 1; Ctrl-N still creates a session.
[ "$fzf_status" -le 1 ] || exit 0

[ -n "$selected" ] || exit 0
key="${selected%%$'\n'*}"
selected="${selected#*$'\n'}"
IFS="$sep" read -r _ target _ <<< "$selected"

case "$key" in
  ctrl-n) action=new ;;
  ctrl-o) action=shell ;;
  ctrl-x) action=stop ;;
  ctrl-d) action=remove ;;
  *)
    if [[ $target = %* ]]; then
      action=jump
    else
      action=resume
    fi
    ;;
esac

# Let the action's output stream to the screen as it happens, so you see git
# and tmux working ("Preparing worktree..."), while keeping a copy: on failure
# the copy is shown again on a clean screen instead of being lost under
# whatever the list left behind. The prompts the actions open are fzf on the
# tty, so they are unaffected by tee-ing stderr. The tee is on stderr only:
# git writes its progress there, and stdout is what the actions print for us.
errors="$(mktemp "${TMPDIR:-/tmp}/pimux-errors.XXXXXXXX")" || exit 1
# Removing the popup's own session can close its terminal before we return.
trap 'rm -f -- "$errors"' EXIT
trap 'exit 130' HUP TERM
clear
if [ "$action" = new ]; then
  "$plugin_dir/pimux-new.sh" 2> >(tee -- "$errors" >&2)
elif [ -n "$target" ]; then
  "$plugin_dir/pimux-action.sh" "$action" "$target" 2> >(tee -- "$errors" >&2)
else
  rm -f -- "$errors"
  exit 0
fi
status=$?
# tee runs asynchronously; make sure the copy is complete before reading it.
wait

# Show what went wrong and wait for Enter or Esc. fzf, not read: bash's read
# cannot see Esc, so it silently swallowed it and the message piled up on
# every retry. --no-input hides the editor row, so there is no stray cursor
# blinking under the message; only the keypress matters.
show_errors() {
  local footer=$1
  clear
  cat -- "$errors"
  rm -f -- "$errors"
  fzf --disabled --no-input --reverse --info=hidden --no-separator --height=2 \
    --footer="$footer" --bind='enter:abort' < /dev/null >/dev/null 2>&1
  true
}
# 0 means you navigated away (jump/resume/shell/new), so the popup closes.
# $back means nothing took you elsewhere: a cancelled or declined prompt, or a
# stop/remove that finished while you are still looking at the list.
if [ "$status" -eq "$back" ]; then
  rm -f -- "$errors"
  exec "$plugin_dir/pimux-list.sh"
fi
if [ "$status" -eq 0 ]; then
  rm -f -- "$errors"
  exit 0
fi
# 2 is "navigated away but with a warning" (a failed setup hook): the new
# session is already in front of you, so show the message and close.
if [ "$status" -eq 2 ]; then
  show_errors 'enter/esc close'
  exit 0
fi
# Keep errors visible, then return to the list rather than vanishing.
show_errors 'enter/esc back to list'
exec "$plugin_dir/pimux-list.sh"
