#!/usr/bin/env bash

# Publishes coding agent state to the tmux pane this runs in, for agents.tmux.
# Meant to be called from an agent's hooks; a no-op outside tmux.
#
# usage: agents.sh busy|done|wait|clear
#        agents.sh                (reads a claude-code hook payload on stdin)
#
# Given no state, it reads the hook payload and derives one from
# hook_event_name, so every claude-code hook registers the same command and the
# event mapping lives here rather than spread across settings.json. The payload
# also carries transcript_path, which the agent list reads the session title
# from; that is recorded rather than resolved here, because the title does not
# exist yet at session start.

if [ -z "$TMUX" ] || [ -z "$TMUX_PANE" ]; then
  exit 0
fi

publish() {
  case $1 in
    busy | done)
      tmux set-option -p -t "$TMUX_PANE" @agent_state "$1" 2>/dev/null
      ;;
    wait)
      # claude-code holds this notification back a few seconds and drops it if
      # the prompt gets answered first, so it can still land after the turn
      # ended. Only a turn in flight can be blocked, so ignore it otherwise.
      case "$(tmux show-option -pqv -t "$TMUX_PANE" @agent_state 2>/dev/null)" in
        busy | wait) tmux set-option -p -t "$TMUX_PANE" @agent_state wait 2>/dev/null ;;
      esac
      ;;
    clear)
      tmux set-option -pu -t "$TMUX_PANE" @agent_state 2>/dev/null
      ;;
  esac
}

# Redraw now instead of waiting for the next status-interval tick.
redraw() { tmux refresh-client -S 2>/dev/null; }

if [ -n "${1:-}" ]; then
  case $1 in
    busy | done | wait | clear) publish "$1" ;;
    *)
      printf 'usage: %s [busy|done|wait|clear]\n' "${0##*/}" >&2
      exit 1
      ;;
  esac
  redraw
  exit 0
fi

type jq >/dev/null 2>&1 || exit 0
{ read -r event; read -r transcript; } < <(
  jq -r '.hook_event_name // "", .transcript_path // ""' 2>/dev/null
)

[ -n "$transcript" ] && tmux set-option -p -t "$TMUX_PANE" @agent_transcript "$transcript" 2>/dev/null

case "$event" in
  UserPromptSubmit | PostToolUse) publish busy ;;
  Notification) publish wait ;;
  Stop) publish done ;;
  SessionStart | SessionEnd) publish clear ;;
esac

redraw

exit 0
