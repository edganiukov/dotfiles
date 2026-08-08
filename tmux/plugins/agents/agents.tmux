#!/usr/bin/env bash

# Flags windows where a coding agent (claude-code, pi) is running.
#
# Agents publish their state into the pane option @agent_state, via
# agents.sh for hook-based agents or tmux set-option -p directly:
#
#   busy - agent is working
#   done - agent finished its turn and is idle
#   wait - agent is blocked on you, asking for permission or an answer
#
# Each window folds its panes' states into the status line, loudest state wins.
# The current window skips its own active pane, so the tab already in front of
# you never flags the agent you are looking at.
#
# Put #{agents} in window-status-format and window-status-current-format
# to place the indicator.
#
# prefix + @agents-key lists every agent on the server in a popup and
# switches to the one you pick.

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

readonly busy_icon="$(get_tmux_option "@agents-busy-icon" "~")"
readonly done_icon="$(get_tmux_option "@agents-done-icon" "^")"
readonly wait_icon="$(get_tmux_option "@agents-wait-icon" "!")"
readonly busy_style="$(get_tmux_option "@agents-busy-style" "#[fg=#665C54]")"
readonly done_style="$(get_tmux_option "@agents-done-style" "#[fg=#B8BB26]")"
readonly wait_style="$(get_tmux_option "@agents-wait-style" "#[fg=#FE8019]#[bold]")"
readonly placeholder="#{agents}"

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
    out="#{?#{m:*$1*,$states},$2$3#[default],$out}"
    shift 3
  done
  printf '%s' "$out"
}

# $1 - option to interpolate, $2 - indicator to substitute in
interpolate() {
  local value="$(tmux show-option -gqv "$1")"
  tmux set-option -gq "$1" "${value//"$placeholder"/$2}"
}

interpolate "window-status-format" "$(indicator '#{P:#{@agent_state}}')"
interpolate "window-status-current-format" "$(indicator '#{P:#{@agent_state},}')"

readonly key="$(get_tmux_option "@agents-key" "a")"
readonly plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if type fzf >/dev/null 2>&1; then
  tmux bind-key "$key" if-shell "$plugin_dir/agents-list.sh --any" \
    "display-popup -E -w 60% -h 40% '$plugin_dir/agents-list.sh'" \
    "display-message 'agents: none running'"
else
  tmux display-message "agents: fzf not found on PATH, agent list unbound"
fi
