#!/usr/bin/env bash

# Flags windows where pi is running.
#
# pi/extensions/tmux.ts publishes state into the pane option @agent_state:
#
#   busy - agent is working
#   done - agent finished its turn and is idle
#   wait - agent is blocked on you, asking for permission or an answer
#
# pi also publishes @agent_name=pi, which names the window and lets the agent
# list find it when it runs as node. See tmux.conf's automatic-rename-format.
#
# Each window folds its panes' states into the status line, loudest state wins.
# The current window skips its own active pane, so the tab already in front of
# you never flags the agent you are looking at.
#
# Put #{pimux} in window-status-format and window-status-current-format
# to place the indicator.
#
# prefix + @pimux-key lists pi sessions in a popup and switches to the one
# you pick. Ctrl-N creates a worktree, branch, tmux session and pi session.

readonly plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$plugin_dir/pimux-common.sh"

readonly busy_icon="$(get_tmux_option "@pimux-busy-icon" "◌")"
readonly done_icon="$(get_tmux_option "@pimux-done-icon" "◉")"
readonly wait_icon="$(get_tmux_option "@pimux-wait-icon" "✦")"
readonly busy_style="$(get_tmux_option "@pimux-busy-style" "#[fg=#FABD2F]")"
readonly done_style="$(get_tmux_option "@pimux-done-style" "#[fg=#B8BB26]")"
readonly wait_style="$(get_tmux_option "@pimux-wait-style" "#[fg=#FB4934]#[bold]")"
readonly placeholder="#{pimux}"

# $1 - format expanding to the states of the panes to watch.
# States are listed quietest first; each one wraps the previous as its else
# branch, so the loudest state present in the window is the one that shows.
indicator() {
  local states=$1
  local out=""
  set -- busy "$busy_style" "$busy_icon" \
    done "$done_style" "$done_icon" \
    wait "$wait_style" "$wait_icon"
  while [ $# -gt 0 ]; do
    out="#{?#{m:*$1*,$states},$2$3#[default] ,$out}"
    shift 3
  done
  printf '%s' "$out"
}

# $1 - option, $2 - replacement, $3 - optional placeholder
interpolate() {
  local value="$(tmux show-option -gqv "$1")"
  local marker="${3:-$placeholder}"
  tmux set-option -gq "$1" "${value//"$marker"/"$2"}"
}

# Ignore state left behind by other agents, including old Claude hooks.
readonly state="#{?$pi_pane,#{@agent_state},}"
interpolate "window-status-format" "$(indicator "#{P:$state}")"
interpolate "window-status-current-format" "$(indicator "#{P:$state,}")"
interpolate "status-right" "#(\"$plugin_dir/pimux-status.sh\")" '#{pimux_blocked}'

readonly key="$(get_tmux_option "@pimux-key" "a")"
readonly width="$(get_tmux_option "@pimux-width" "50%")"
readonly height="$(get_tmux_option "@pimux-height" "30%")"

if type fzf >/dev/null 2>&1; then
  # A percentage, so tmux keeps rescaling the popup when the window is resized.
  tmux bind-key "$key" display-popup -E -w "$width" -h "$height" \
    -d '#{pane_current_path}' "\"$plugin_dir/pimux-list.sh\""
else
  tmux display-message "pimux: fzf not found on PATH, agent list unbound"
fi
