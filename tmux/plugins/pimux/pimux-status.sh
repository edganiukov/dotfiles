#!/usr/bin/env bash

# Global notice: unlike tab indicators, include Pi panes in every tmux session.
readonly plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$plugin_dir/pimux-common.sh"

count=0
while IFS= read -r waiting; do
  [ "$waiting" != 1 ] || ((count += 1))
done < <(tmux list-panes -a -F "#{&&:$pi_pane,#{==:#{@agent_state},wait}}")

if [ "$count" -gt 0 ]; then
  printf '%s%s %s blocked#[default] ' \
    "$(get_tmux_option '@pimux-wait-style' '#[fg=#FE8019]#[bold]')" \
    "$(get_tmux_option '@pimux-wait-icon' '▲')" "$count"
fi
