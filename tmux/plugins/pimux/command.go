package main

import "strings"

// Shell quoting is needed only at the tmux/fzf command-string boundaries.
// Git, tmux actions, Pi, and setup hooks otherwise receive argument arrays.
func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", "'\\''") + "'"
}
