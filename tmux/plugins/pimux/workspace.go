package main

import (
	"path/filepath"
	"regexp"
	"strings"
)

var validName = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9_-]*$`)

type worktree struct{ Path, Branch string }
type workspace struct{ Path, Main, Name string }

func parseWorktrees(text string) []worktree {
	var result []worktree
	var tree worktree
	for _, field := range strings.Split(text, "\x00") {
		switch {
		case strings.HasPrefix(field, "worktree "):
			tree.Path = strings.TrimPrefix(field, "worktree ")
		case strings.HasPrefix(field, "branch refs/heads/"):
			tree.Branch = strings.TrimPrefix(field, "branch refs/heads/")
		case field == "":
			if tree.Path != "" {
				result = append(result, tree)
			}
			tree = worktree{}
		}
	}
	return result
}

func within(path, root string) bool {
	return path == root || strings.HasPrefix(path, root+string(filepath.Separator))
}

func managedPath(main, name string) string { return filepath.Join(main+"-worktrees", name) }
