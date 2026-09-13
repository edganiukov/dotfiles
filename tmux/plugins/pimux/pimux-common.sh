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

# Exit status meaning "nothing happened, show the list again". fzf returns it
# on Escape, and prompts reuse it for a declined confirmation, so the list
# script treats one code as back-to-list wherever it comes from.
readonly back=130

# Prompt for a line using fzf's editor, so Escape works immediately: bash's
# read cannot see Escape at all, it only returns on Enter. Prints the answer;
# returns $back on Escape.
ask() {
  local prompt=$1
  fzf --disabled --reverse --info=hidden --no-separator \
    --prompt="$prompt" --footer="${2:-enter confirm | esc back}" \
    --bind='enter:accept-or-print-query' < /dev/null
}

main_worktree() {
  local entry
  IFS= read -r -d '' entry < <(git -C "$1" worktree list --porcelain -z 2>/dev/null) || return 1
  printf '%s' "${entry#worktree }"
}
