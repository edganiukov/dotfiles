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
#
# The question goes in the header, folded to the terminal width, not in the
# prompt: fzf never wraps a prompt, it truncates it to the width, so a long
# question in a narrow popup was simply cut off. The input line below gets a
# short prompt of its own, so what you type sits on its own row.
ask() {
  local question=$1 width
  # Size from the terminal itself: here stdout is captured by $(ask ...) and
  # stderr is tee'd by the list script, so tput has no tty on either stream
  # and would fall back to 80 regardless of how narrow the popup really is.
  width=${COLUMNS:-$(tput cols < /dev/tty 2> /dev/null)}
  width=${width:-80}
  fzf --disabled --reverse --info=hidden --no-separator \
    --header="$(printf '%s' "$question" | fold -s -w "$((width - 4))")" \
    --prompt='> ' --footer="${2:-enter confirm | esc back}" \
    --bind='enter:accept-or-print-query' < /dev/null
}

main_worktree() {
  local entry
  IFS= read -r -d '' entry < <(git -C "$1" worktree list --porcelain -z 2>/dev/null) || return 1
  printf '%s' "${entry#worktree }"
}
