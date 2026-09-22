package main

import (
	"bytes"
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
	"unicode/utf8"
)

func TestParseWorktrees(t *testing.T) {
	main := "/tmp/repo with 'quotes'"
	linked := main + "/.worktrees/task\nwith\ttabs"
	text := "worktree " + main + "\x00HEAD abc\x00branch refs/heads/main\x00\x00" +
		"worktree " + linked + "\x00HEAD def\x00branch refs/heads/task\x00locked reason\x00\x00" +
		"worktree /tmp/detached\x00HEAD abc\x00detached\x00\x00"
	got := parseWorktrees(text)
	want := []worktree{{main, "main"}, {linked, "task"}, {"/tmp/detached", ""}}
	if len(got) != len(want) {
		t.Fatalf("got %#v, want %#v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("got %#v, want %#v", got[i], want[i])
		}
	}
}

func TestWithin(t *testing.T) {
	for _, tc := range []struct {
		path string
		want bool
	}{
		{"/repo/.worktrees/task", true},
		{"/repo/.worktrees/task/src", true},
		{"/repo/.worktrees/task-other", false},
		{"/repo/.worktrees", false},
	} {
		if got := within(tc.path, "/repo/.worktrees/task"); got != tc.want {
			t.Errorf("within(%q) = %v", tc.path, got)
		}
	}
}

func TestParsePane(t *testing.T) {
	p, err := parsePane(strings.Join([]string{"%4", "$1", "task", "2.1", "/repo", "done", "123", "", "1"}, sep))
	if err != nil || !p.Pi || p.State != done || p.Since != "123" || p.Title != "" || p.label() != "task" {
		t.Fatalf("pane = %#v, err = %v", p, err)
	}
	p.Title = "Refactor auth"
	if p.label() != "task (Refactor auth)" {
		t.Fatal(p.label())
	}
	if _, err := parsePane("%4" + sep + "truncated"); err == nil {
		t.Fatal("accepted incomplete pane record")
	}
}

func TestStateAge(t *testing.T) {
	now := time.Unix(200000, 0)
	for _, tc := range []struct{ since, want string }{
		{"200000", "0s"}, {"199995", "5s"}, {"199941", "59s"},
		{"199940", "1m"}, {"196401", "59m"}, {"196400", "1h"},
		{"113601", "23h"}, {"113600", "1d"}, {"27200", "2d"},
		{"", ""}, {"invalid", ""},
	} {
		if got := stateAge(tc.since, now); got != tc.want {
			t.Errorf("stateAge(%q) = %q, want %q", tc.since, got, tc.want)
		}
	}
}

func TestRowLayout(t *testing.T) {
	r := makeRow("%1", "task", "0.0", "repo", done, "", "5m", "task")
	if r.Rank != 2 || r.ID != "%1" || strings.Count(r.Display, "task") != 1 || !strings.HasPrefix(r.Display, "\x1b[38;5;142m✤\x1b[0m ") {
		t.Fatalf("row = %#v", r)
	}
	if !strings.Contains(r.Display, "done") {
		t.Fatalf("missing state label: %q", r.Display)
	}
	// A stopped row replaces that label with why it can be removed.
	stopped := makeRow("/worktree", "task", "-", "repo", "stopped", "unmerged", "3d", "")
	if strings.Contains(stopped.Display, "stopped") || !strings.Contains(stopped.Display, "unmerged") {
		t.Fatalf("stopped row = %q", stopped.Display)
	}
	if got := truncate("αβγδε", 4); got != "αβγ…" {
		t.Fatalf("truncate = %q", got)
	}
}

func TestPromptQuestion(t *testing.T) {
	screen := "Earlier conversation\n──────\n\n Allow git push?\n\n → Yes\n No\n\n ↑↓ navigate\n\n──────\n~/repo\n0.0%/0\n"
	if got := promptQuestion(screen); got != "Allow git push?" {
		t.Fatalf("question = %q", got)
	}
	if got := promptQuestion("Earlier conversation\n─────\n\n─────\nfooter"); got != "" {
		t.Fatalf("empty box = %q", got)
	}
}

func TestWrap(t *testing.T) {
	for _, text := range []string{"Stop Pi in task? Type task to confirm:", "a-very-long-word-without-spaces", "αβγδεζηθ", "two  spaces"} {
		got := wrap(text, 8)
		for _, line := range strings.Split(got, "\n") {
			if utf8.RuneCountInString(line) > 8 {
				t.Errorf("line too wide: %q", line)
			}
		}
		if strings.ReplaceAll(got, "\n", "") != text {
			t.Errorf("wrapping changed content: %q -> %q", text, got)
		}
	}
	if got := wrap("abc", 0); got != "a\nb\nc" {
		t.Fatalf("narrow wrap = %q", got)
	}
}

func TestShellQuote(t *testing.T) {
	for _, value := range []string{"", "plain", "repo with 'quotes'", "$(echo unsafe);\n*.go"} {
		out, err := exec.Command("sh", "-c", "printf '%s' "+shellQuote(value)).Output()
		if err != nil || string(out) != value {
			t.Errorf("round trip %q: %q, %v", value, out, err)
		}
	}
}

func TestOutputSeparatesDiagnostics(t *testing.T) {
	a := &app{ctx: context.Background(), dir: t.TempDir()}
	got, err := a.output("sh", "-c", "printf answer; printf diagnostic >&2")
	if err != nil || got != "answer" {
		t.Fatalf("output = %q, err = %v", got, err)
	}
	_, err = a.output("sh", "-c", "echo broken >&2; exit 1")
	if err == nil || !strings.Contains(err.Error(), "broken") {
		t.Fatalf("missing diagnostic: %v", err)
	}
}

func TestCommandCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	a := &app{ctx: ctx, dir: t.TempDir()}
	cancel()
	marker := filepath.Join(a.dir, "should-not-exist")
	if _, err := a.output("sh", "-c", "touch "+shellQuote(marker)); err == nil {
		t.Fatal("cancelled command succeeded")
	}
	if _, err := os.Stat(marker); !os.IsNotExist(err) {
		t.Fatal("cancelled command ran")
	}
}

func TestRefreshFailurePreservesSnapshot(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "rows")
	if err := os.WriteFile(path, []byte("existing rows"), 0600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PIMUX_ROWS_FILE", path)
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	a := &app{ctx: ctx, dir: dir, out: &bytes.Buffer{}}
	if err := a.refresh(); err == nil {
		t.Fatal("refresh with cancelled discovery succeeded")
	}
	got, err := os.ReadFile(path)
	if err != nil || string(got) != "existing rows" {
		t.Fatalf("snapshot = %q, err = %v", got, err)
	}
	entries, err := os.ReadDir(dir)
	if err != nil || len(entries) != 1 {
		t.Fatalf("temporary file leaked: %v, %v", entries, err)
	}
}
