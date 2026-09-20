package main

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type row struct {
	Rank        int
	ID, Display string
}

func stateDisplay(state agentState) (rank int, icon, label string) {
	switch state {
	case wait:
		return 0, "\x1b[1;38;5;167m◆\x1b[0m", "blocked"
	case done:
		return 1, "\x1b[38;5;142m✤\x1b[0m", "done"
	case busy:
		return 2, "\x1b[38;5;214m◌\x1b[0m", "working"
	case "stopped":
		return 4, "\x1b[38;5;142m▢\x1b[0m", "stopped"
	default:
		return 3, "\x1b[38;5;142m▢\x1b[0m", "idle"
	}
}

func truncate(text string, width int) string {
	runes := []rune(text)
	if len(runes) > width {
		return string(runes[:width-1]) + "…"
	}
	return text
}

func stateAge(since string, now time.Time) string {
	timestamp, err := strconv.ParseInt(since, 10, 64)
	if err != nil {
		return ""
	}
	seconds := now.Unix() - timestamp
	switch {
	case seconds < 60:
		return fmt.Sprintf("%ds", seconds)
	case seconds < 3600:
		return fmt.Sprintf("%dm", seconds/60)
	case seconds < 86400:
		return fmt.Sprintf("%dh", seconds/3600)
	default:
		return fmt.Sprintf("%dd", seconds/86400)
	}
}

func makeRow(id, session, location, project string, state agentState, age, title string) row {
	if title == session {
		title = ""
	}

	rank, icon, label := stateDisplay(state)
	return row{rank, id, fmt.Sprintf("%s %-12s %-5s %-14s %-8s %4s  %s",
		icon, truncate(session, 12), location, truncate(project, 14), label, age, truncate(title, 40))}
}

var managedDirectory = regexp.MustCompile(`^(.*)-worktrees/[^/]+(/.*)?$`)

// Pi's blocking prompt replaces the editor between the bottom two rule lines.
// Its first nonblank line is the question, not the choices, hints or footer.
func promptQuestion(screen string) string {
	lines := strings.Split(screen, "\n")
	rules, question := 0, ""
	for i := len(lines) - 1; i >= 0; i-- {
		line := lines[i]
		if strings.Contains(line, "──") {
			rules++
			if rules == 2 {
				break
			}
			continue
		}
		if rules == 1 && strings.TrimSpace(line) != "" {
			question = strings.TrimSpace(line)
		}
	}
	return question
}
