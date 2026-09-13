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
  fmt="${fmt}${sep}#{pane_current_path}${sep}#{@agent_state}"
  fmt="${fmt}${sep}#{@agent_session}${sep}$pi_pane"

  local pane sess widx pidx path state title is_pi
  while IFS="$sep" read -r pane sess widx pidx path state title is_pi; do
    [ "$is_pi" = 1 ] || continue

    printf '%s%s%s%s%s %-7s %-8s %-5s %-12s %-8s %s\n' \
      "$(rank "$state")" "$sep" "$pane" "$sep" \
      "$(icon "$state")" "pi" "$sess" "$widx.$pidx" \
      "$(truncate_to "${path##*/}" 16)" "$(label "$state")" "$(truncate_to "$title" 50)"
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
              printf '4%s%s%s○ %-7s %-8s %-5s %-12s %-8s %s\n' \
                "$sep" "$path" "$sep" pi "$branch" - \
                "$(truncate_to "${main##*/}" 16)" stopped "$branch"
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

if [ "$action" = new ]; then
  "$plugin_dir/pimux-new.sh"
elif [ -n "$target" ]; then
  "$plugin_dir/pimux-action.sh" "$action" "$target"
else
  exit 0
fi
status=$?
if [ "$action" = new ] && [ "$status" -eq 130 ]; then
  exec "$plugin_dir/pimux-list.sh"
fi
# Keep errors visible rather than closing the popup immediately.
[ "$status" -eq 0 ] || read -r -p "Press Enter to close. "
exit "$status"
