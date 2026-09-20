package main

import (
	"errors"
	"os/exec"
	"strings"
)

var Err = errors.New("prompt cancelled")

func exitCode(err error) int {
	if err == nil {
		return 0
	}

	var exit *exec.ExitError
	if errors.As(err, &exit) {
		return exit.ExitCode()
	}

	return -1
}

func wrap(text string, width int) string {
	if width < 1 {
		width = 1
	}

	var lines []string
	for _, line := range strings.Split(text, "\n") {
		runes := []rune(line)
		for len(runes) > width {
			cut := width
			for i := width - 1; i >= 0; i-- {
				if runes[i] == ' ' || runes[i] == '\t' {
					cut = i + 1
					break
				}
			}

			lines = append(lines, string(runes[:cut]))
			runes = runes[cut:]
		}

		lines = append(lines, string(runes))
	}

	return strings.Join(lines, "\n")
}
