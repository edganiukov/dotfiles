#!/usr/bin/env bash

# Publishes coding agent state to the tmux pane this runs in, for agents.tmux.
# Meant to be called from an agent's hooks; a no-op outside tmux.
#
# usage: agents.sh busy|done|wait|clear
#        agents.sh transcript   (reads a claude-code hook payload on stdin)
#
# "transcript" records where claude-code keeps this session's log, so the agent
# list can read its title later. The title is resolved lazily rather than stored
# here because it does not exist yet at session start.

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
  transcript)
    if type jq >/dev/null 2>&1; then
      path="$(jq -r '.transcript_path // empty' 2>/dev/null)"
      [ -n "$path" ] && tmux set-option -p -t "$TMUX_PANE" @agent_transcript "$path" 2>/dev/null
    fi
    ;;
  *)
    printf 'usage: %s busy|done|wait|clear|transcript\n' "${0##*/}" >&2
    exit 1
    ;;
esac

# Redraw now instead of waiting for the next status-interval tick.
tmux refresh-client -S 2>/dev/null

exit 0
