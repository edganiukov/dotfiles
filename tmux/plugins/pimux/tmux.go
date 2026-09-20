package main

import (
	"fmt"
	"strings"
)

const sep = "\x1f"
const piPane = "#{&&:#{==:#{pane_dead},0},#{||:#{==:#{@agent_name},pi},#{==:#{pane_current_command},pi}}}"

const paneFormat = "#{pane_id}" + sep + "#{session_id}" + sep + "#{session_name}" + sep +
	"#{window_index}.#{pane_index}" + sep + "#{pane_current_path}" + sep + "#{@agent_state}" + sep +
	"#{@agent_since}" + sep + "#{@agent_session}" + sep + piPane

type agentState string

const (
	busy agentState = "busy"
	done agentState = "done"
	wait agentState = "wait"
)

type pane struct {
	ID, SessionID, Session, Location, Path string
	State                                  agentState
	Since, Title                           string
	Pi                                     bool
}

func parsePane(line string) (pane, error) {
	f := strings.Split(line, sep)
	if len(f) != 9 || f[0] == "" {
		return pane{}, fmt.Errorf("invalid tmux pane record")
	}
	return pane{f[0], f[1], f[2], f[3], f[4], agentState(f[5]), f[6], f[7], f[8] == "1"}, nil
}

func (p pane) label() string {
	if p.Title != "" && p.Title != p.Session {
		return p.Session + " (" + p.Title + ")"
	}
	return p.Session
}
