#!/usr/bin/env bash

# Publishes coding agent state to the tmux pane this runs in, for agent-watch.tmux.
# Meant to be called from an agent's hooks; a no-op outside tmux.
#
# usage: agent-watch.sh busy|done|wait|clear

if [ -z "$TMUX" ] || [ -z "$TMUX_PANE" ]; then
  exit 0
fi

case "$1" in
  busy | done | wait)
    tmux set-option -p -t "$TMUX_PANE" @agent_state "$1" 2>/dev/null
    ;;
  clear)
    tmux set-option -pu -t "$TMUX_PANE" @agent_state 2>/dev/null
    ;;
  *)
    printf 'usage: %s busy|done|wait|clear\n' "${0##*/}" >&2
    exit 1
    ;;
esac

# Redraw now instead of waiting for the next status-interval tick.
tmux refresh-client -S 2>/dev/null

exit 0
