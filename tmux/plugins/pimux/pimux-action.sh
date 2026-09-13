#!/usr/bin/env bash

readonly plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$plugin_dir/pimux-common.sh"

# Resolve a live Pi pane without relying on a possibly stale picker row.
# Also yields a human label: a bare pane id like %3 says nothing about which
# session is about to be acted on, so prompts name the tmux session and the
# pi session instead.
pane_info() {
  local info session_name pi_session
  info="$(tmux display-message -p -t "$1" \
    "#{session_id}${sep}#{pane_current_path}${sep}$pi_pane${sep}#{session_name}${sep}#{@agent_session}")" ||
    fail "pane no longer exists: $1"
  IFS="$sep" read -r session path is_pi session_name pi_session <<< "$info"
  [ "$is_pi" = 1 ] || fail "Pi is no longer running in pane $1"
  label="$session_name"
  [ -z "$pi_session" ] || [ "$pi_session" = "$session_name" ] || label="$session_name ($pi_session)"
}

jump() {
  pane_info "$1"
  tmux select-window -t "$1" && tmux select-pane -t "$1" && tmux switch-client -t "$session"
}

# Only worktrees created with the manager's path/branch convention are removable.
workspace_info() {
  worktree="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" || fail "worktree not found: $1"
  main="$(main_worktree "$worktree")" || fail "could not locate the main worktree"
  name="${worktree##*/}"
  [[ $name =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ && $worktree = "$main-worktrees/$name" ]] ||
    fail "not a managed workspace: $worktree"
  [ "$(git -C "$worktree" symbolic-ref --quiet --short HEAD)" = "$name" ] ||
    fail "workspace branch has changed; manage it manually: $worktree"
}

# Reuse a shell-only session, but never a same-named session from another project.
workspace_session() {
  session=""
  if tmux has-session -t "=$name" 2>/dev/null; then
    local cwd
    while IFS= read -r cwd; do
      if [[ $cwd = "$worktree" || $cwd = "$worktree/"* ]]; then
        session="$(tmux display-message -p -t "=$name:" '#{session_id}')"
        return
      fi
    done < <(tmux list-panes -s -t "=$name" -F '#{pane_current_path}')
    fail "tmux session already exists in another directory: $name"
  fi
}

check_removable() {
  local cwd changes paths
  paths="$(tmux list-panes -a -F '#{pane_current_path}')" || fail "could not check active tmux panes"
  while IFS= read -r cwd; do
    [[ $cwd != "$worktree" && $cwd != "$worktree/"* ]] ||
      fail "workspace is in use; stop Pi and close its shell windows first"
  done <<< "$paths"

  changes="$(git -C "$worktree" status --porcelain --untracked-files=all --ignored)" ||
    fail "could not check workspace changes"
  [ -z "$changes" ] || fail "workspace has uncommitted, untracked or ignored files"
  git -C "$main" merge-base --is-ancestor "refs/heads/$name" HEAD ||
    fail "workspace has commits not merged into the main checkout's HEAD"
}

readonly action="${1:-}"
readonly target="${2:-}"
[ -n "$target" ] || fail "no session selected"

case "$action" in
  jump) jump "$target" ;;
  stop)
    [[ $target = %* ]] || fail "this workspace is already stopped"
    pane_info "$target"
    answer="$(ask "Stop Pi in $label? Its branch and worktree will be kept. [y/N] ")" || exit "$back"
    [[ $answer = y || $answer = Y ]] || exit "$back"
    pane_info "$target"
    tmux kill-pane -t "$target" || exit 1
    # You are still at the list; the row just went away.
    exit "$back"
    ;;
  resume)
    workspace_info "$target"
    # Another client may have resumed Pi since the list was rendered.
    while IFS="$sep" read -r pane cwd; do
      if [[ $cwd = "$worktree" || $cwd = "$worktree/"* ]]; then
        jump "$pane"
        exit
      fi
    done < <(tmux list-panes -a -F "#{?$pi_pane,#{pane_id}${sep}#{pane_current_path},}")
    type pi >/dev/null 2>&1 || fail "pi not found on PATH"
    workspace_session
    if [ -n "$session" ]; then
      window="$(tmux new-window -d -P -F '#{window_id}' -t "$session:" -c "$worktree" -- pi --continue --name "$name")" || exit 1
      tmux select-window -t "$window" && tmux switch-client -t "$session"
    else
      tmux new-session -d -s "$name" -c "$worktree" -- pi --continue --name "$name" &&
        tmux switch-client -t "=$name"
    fi
    ;;
  shell)
    if [[ $target = %* ]]; then
      pane_info "$target"
      worktree="$(git -C "$path" rev-parse --show-toplevel 2>/dev/null)" || worktree="$path"
    else
      workspace_info "$target"
      workspace_session
    fi
    if [ -n "$session" ]; then
      window="$(tmux new-window -d -P -F '#{window_id}' -t "$session:" -c "$worktree")" || exit 1
      tmux select-window -t "$window" && tmux switch-client -t "$session"
    else
      tmux new-session -d -s "$name" -c "$worktree" && tmux switch-client -t "=$name"
    fi
    ;;
  remove)
    if [[ $target = %* ]]; then
      pane_info "$target"
      workspace_info "$path"
    else
      workspace_info "$target"
    fi
    check_removable
    answer="$(ask "Remove $worktree and branch $name? Type $name to confirm: " "type the name | esc back")" ||
      exit "$back"
    [ "$answer" = "$name" ] || exit "$back"
    # Recheck after the user prompt. Never force removal or branch deletion.
    workspace_info "$worktree"
    check_removable
    git -C "$main" worktree remove "$worktree" && git -C "$main" branch -d "$name" || exit 1
    exit "$back"
    ;;
  *) fail "unknown action: $action" ;;
esac
