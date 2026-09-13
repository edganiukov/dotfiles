#!/usr/bin/env bash

# Shared pane detection and Git helpers. Dead panes may retain old Pi labels.
readonly sep=$'\x1f'
readonly pi_pane='#{&&:#{==:#{pane_dead},0},#{||:#{==:#{@agent_name},pi},#{==:#{pane_current_command},pi}}}'

get_tmux_option() {
  local value
  value="$(tmux show-option -gqv "$1")"
  printf '%s' "${value:-$2}"
}

fail() {
  printf 'pimux: %s\n' "$*" >&2
  exit 1
}

main_worktree() {
  local entry
  IFS= read -r -d '' entry < <(git -C "$1" worktree list --porcelain -z 2>/dev/null) || return 1
  printf '%s' "${entry#worktree }"
}
