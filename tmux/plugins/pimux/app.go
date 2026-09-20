package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"syscall"
	"time"
)

type app struct {
	ctx    context.Context
	dir    string
	exe    string
	out    io.Writer
	errOut io.Writer
}

func (a *app) dispatch(args []string) (outcome, error) {
	if len(args) == 0 {
		return closePopup, a.list()
	}
	switch args[0] {
	case "list":
		if len(args) == 1 {
			return closePopup, a.list()
		}
		if len(args) == 2 && args[1] == "--rows" {
			rows, err := a.rows()
			if err == nil {
				_, err = io.WriteString(a.out, rows)
			}
			return closePopup, err
		}
		if len(args) == 2 && args[1] == "--refresh" {
			return closePopup, a.refresh()
		}
		if len(args) == 2 && args[1] == "--scope" {
			return closePopup, a.toggleScope()
		}
	case "new":
		if len(args) == 1 {
			return a.newSession()
		}
		if len(args) == 2 {
			return a.createSession(args[1])
		}
	case "action":
		if len(args) == 3 {
			return a.action(args[1], args[2])
		}
	case "status":
		if len(args) == 1 {
			return closePopup, a.status()
		}
	case "init":
		if len(args) == 1 {
			return closePopup, a.initTmux()
		}
	}
	return closePopup, fmt.Errorf("usage: pimux [list [--rows|--refresh|--scope] | new [<name>[@<base>]] | action <jump|resume|shell|stop|remove> <target> | status | init]")
}

func (a *app) command(name string, args ...string) *exec.Cmd {
	cmd := exec.CommandContext(a.ctx, name, args...)
	cmd.Dir = a.dir
	// A child may leave inherited pipes open. Cancellation must still allow
	// the popup to exit and its deferred snapshot cleanup to run.
	cmd.WaitDelay = time.Second
	return cmd
}

// Queries keep stdout separate from diagnostics. Callers can deliberately
// ignore errors for optional discovery (e.g. a pane outside a repository).
func (a *app) output(name string, args ...string) (string, error) {
	cmd := a.command(name, args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout, cmd.Stderr = &stdout, &stderr
	if err := cmd.Run(); err != nil {
		if text := strings.TrimSpace(stderr.String()); text != "" {
			return "", fmt.Errorf("%s: %s: %w", name, text, err)
		}
		return "", fmt.Errorf("%s: %w", name, err)
	}
	return strings.TrimRight(stdout.String(), "\r\n"), nil
}

// Mutating commands stream their output, including Git's progress on stderr.
func (a *app) run(name string, args ...string) error {
	cmd := a.command(name, args...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, a.out, a.errOut
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("%s: %w", name, err)
	}
	return nil
}

func (a *app) git(dir string, args ...string) (string, error) {
	return a.output("git", append([]string{"-C", dir}, args...)...)
}

func (a *app) runGit(dir string, args ...string) error {
	return a.run("git", append([]string{"-C", dir}, args...)...)
}

func (a *app) panes() ([]pane, error) {
	text, err := a.output("tmux", "list-panes", "-a", "-F", paneFormat)
	if err != nil {
		return nil, err
	}
	var panes []pane
	for _, line := range strings.Split(text, "\n") {
		if line == "" {
			continue
		}
		p, err := parsePane(line)
		if err != nil {
			return nil, err
		}
		panes = append(panes, p)
	}
	return panes, nil
}

func (a *app) paneInfo(id string) (pane, error) {
	text, err := a.output("tmux", "display-message", "-p", "-t", id, paneFormat)
	if err != nil {
		return pane{}, fmt.Errorf("pane no longer exists: %s", id)
	}
	p, err := parsePane(text)
	if err != nil || p.ID != id || !p.Pi {
		return pane{}, fmt.Errorf("Pi is no longer running in pane %s", id)
	}
	return p, nil
}

func (a *app) option(name, fallback string) string {
	value, err := a.output("tmux", "show-option", "-gqv", name)
	if err != nil || value == "" {
		return fallback
	}
	return value
}

func (a *app) status() error {
	panes, err := a.panes()
	if err != nil {
		return err
	}
	count := 0
	for _, p := range panes {
		if p.Pi && p.State == wait {
			count++
		}
	}
	if count > 0 {
		_, err = fmt.Fprintf(a.out, "%s%s %d blocked#[default] ",
			a.option("@pimux-wait-style", "#[fg=#FB4934]#[bold]"), a.option("@pimux-wait-icon", "◆"), count)
	}
	return err
}

func (a *app) interpolate(option, marker, replacement string) error {
	value, err := a.output("tmux", "show-option", "-gqv", option)
	if err != nil {
		return err
	}
	return a.run("tmux", "set-option", "-gq", option, strings.ReplaceAll(value, marker, replacement))
}

func (a *app) initTmux() error {
	// Fold every pane, including the active pane in the selected window.
	// A live Pi pane with no published state is idle; other panes stay unmarked.
	// Wrap the quietest states first so waiting wins over done, busy and idle.
	states := "#{P:#{?" + piPane + ",#{?@agent_state,#{@agent_state},idle},}}"
	indicator := ""
	for _, s := range []struct{ name, icon, style string }{
		{"idle", "▢", "#[fg=#B8BB26]"},
		{"busy", "◌", "#[fg=#FABD2F]"},
		{"done", "✤", "#[fg=#B8BB26]"},
		{"wait", "◆", "#[fg=#FB4934]#[bold]"},
	} {
		icon := a.option("@pimux-"+s.name+"-icon", s.icon)
		style := a.option("@pimux-"+s.name+"-style", s.style)
		indicator = "#{?#{m:*" + s.name + "*," + states + "}," + style + icon + "#[default] ," + indicator + "}"
	}
	for _, option := range []string{"window-status-format", "window-status-current-format"} {
		if err := a.interpolate(option, "#{pimux}", indicator); err != nil {
			return err
		}
	}
	if err := a.interpolate("status-right", "#{pimux_blocked}", "#("+shellQuote(a.exe)+" status)"); err != nil {
		return err
	}
	if _, err := exec.LookPath("fzf"); err != nil {
		return a.run("tmux", "display-message", "pimux: fzf not found on PATH, agent list unbound")
	}
	return a.run("tmux", "bind-key", a.option("@pimux-key", "a"), "display-popup", "-E",
		"-w", a.option("@pimux-width", "50%"), "-h", a.option("@pimux-height", "30%"),
		"-d", "#{pane_current_path}", shellQuote(a.exe)+" list")
}

func (a *app) worktrees(dir string) ([]worktree, error) {
	text, err := a.git(dir, "worktree", "list", "--porcelain", "-z")
	if err != nil {
		return nil, err
	}
	return parseWorktrees(text), nil
}

func (a *app) mainWorktree(dir string) (string, error) {
	trees, err := a.worktrees(dir)
	if err != nil || len(trees) == 0 {
		return "", fmt.Errorf("could not locate the main worktree")
	}
	return trees[0].Path, nil
}

func (a *app) workspaceInfo(path string) (workspace, error) {
	root, err := a.git(path, "rev-parse", "--show-toplevel")
	if err != nil {
		return workspace{}, fmt.Errorf("worktree not found: %s", path)
	}
	main, err := a.mainWorktree(root)
	if err != nil {
		return workspace{}, err
	}
	w := workspace{root, main, filepath.Base(root)}
	if !validName.MatchString(w.Name) || w.Path != managedPath(w.Main, w.Name) {
		return workspace{}, fmt.Errorf("not a managed workspace: %s", root)
	}
	branch, err := a.git(root, "symbolic-ref", "--quiet", "--short", "HEAD")
	if err != nil || branch != w.Name {
		return workspace{}, fmt.Errorf("workspace branch has changed; manage it manually: %s", root)
	}
	return w, nil
}

// Reuse a shell-only session, but not a same-named session from another repo.
func (a *app) workspaceSession(w workspace) (string, error) {
	if _, err := a.output("tmux", "has-session", "-t", "="+w.Name); err != nil {
		return "", nil
	}
	paths, err := a.output("tmux", "list-panes", "-s", "-t", "="+w.Name, "-F", "#{pane_current_path}")
	if err != nil {
		return "", err
	}
	for _, path := range strings.Split(paths, "\n") {
		if within(path, w.Path) {
			return a.output("tmux", "display-message", "-p", "-t", "="+w.Name+":", "#{session_id}")
		}
	}
	return "", fmt.Errorf("tmux session already exists in another directory: %s", w.Name)
}

// Says in one word why Ctrl-D would refuse this stopped workspace, so the
// list shows which branches are finished with. It asks the same questions as
// checkRemovable, in the same order, and "merged" means all of them passed.
func (a *app) removability(w workspace, panes []pane) string {
	for _, p := range panes {
		if within(p.Path, w.Path) {
			return "in use"
		}
	}
	if changes, err := a.git(w.Path, "status", "--porcelain", "--untracked-files=all", "--ignored"); err != nil || changes != "" {
		return "changes"
	}
	if _, err := a.git(w.Main, "merge-base", "--is-ancestor", "refs/heads/"+w.Name, "HEAD"); err != nil {
		return "unmerged"
	}
	return "merged"
}

func (a *app) checkRemovable(w workspace, stopPane string) error {
	if stopPane != "" {
		p, err := a.paneInfo(stopPane)
		if err != nil {
			return err
		}
		if p.State != done {
			return fmt.Errorf("Pi is not done; stop it before removing the workspace")
		}
		if !within(p.Path, w.Path) {
			return fmt.Errorf("Pi pane has moved out of the workspace; select it again")
		}
	}
	panes, err := a.panes()
	if err != nil {
		return fmt.Errorf("could not check active tmux panes: %w", err)
	}
	for _, p := range panes {
		if p.ID != stopPane && within(p.Path, w.Path) {
			return fmt.Errorf("workspace is in use; stop Pi and close its shell windows first")
		}
	}
	changes, err := a.git(w.Path, "status", "--porcelain", "--untracked-files=all", "--ignored")
	if err != nil {
		return fmt.Errorf("could not check workspace changes: %w", err)
	}
	if changes != "" {
		return fmt.Errorf("workspace has uncommitted, untracked or ignored files")
	}
	if _, err := a.git(w.Main, "merge-base", "--is-ancestor", "refs/heads/"+w.Name, "HEAD"); err != nil {
		return fmt.Errorf("workspace has commits not merged into the main checkout's HEAD")
	}
	return nil
}

func (a *app) action(action, target string) (outcome, error) {
	if target == "" {
		return backToList, fmt.Errorf("no session selected")
	}
	switch action {
	case "jump":
		return closePopup, a.jump(target)
	case "resume":
		return closePopup, a.resume(target)
	case "shell":
		return closePopup, a.shell(target)
	case "stop":
		return backToList, a.stop(target)
	case "remove":
		return backToList, a.remove(target)
	default:
		return backToList, fmt.Errorf("unknown action: %s", action)
	}
}

func (a *app) jump(target string) error {
	p, err := a.paneInfo(target)
	if err != nil {
		return err
	}
	if err := a.run("tmux", "select-window", "-t", target); err != nil {
		return err
	}
	if err := a.run("tmux", "select-pane", "-t", target); err != nil {
		return err
	}
	return a.run("tmux", "switch-client", "-t", p.SessionID)
}

func (a *app) stop(target string) error {
	if !strings.HasPrefix(target, "%") {
		return fmt.Errorf("this workspace is already stopped")
	}
	p, err := a.paneInfo(target)
	if err != nil {
		return err
	}
	answer, err := a.ask("Stop Pi in "+p.label()+"? Its branch and worktree will be kept. [y/N] ", "enter confirm | esc back")
	if errors.Is(err, Err) {
		return nil
	}
	if err != nil || (answer != "y" && answer != "Y") {
		return err
	}
	if _, err := a.paneInfo(target); err != nil {
		return err
	}
	return a.run("tmux", "kill-pane", "-t", target)
}

func (a *app) openSession(w workspace, session string, command ...string) error {
	if session != "" {
		args := []string{"new-window", "-d", "-P", "-F", "#{window_id}", "-t", session + ":", "-c", w.Path}
		if len(command) > 0 {
			args = append(append(args, "--"), command...)
		}
		window, err := a.output("tmux", args...)
		if err != nil {
			return err
		}
		if err := a.run("tmux", "select-window", "-t", window); err != nil {
			return err
		}
	} else {
		args := []string{"new-session", "-d", "-s", w.Name, "-c", w.Path}
		if len(command) > 0 {
			args = append(append(args, "--"), command...)
		}
		if err := a.run("tmux", args...); err != nil {
			return err
		}
		session = "=" + w.Name
	}
	return a.run("tmux", "switch-client", "-t", session)
}

func (a *app) resume(target string) error {
	w, err := a.workspaceInfo(target)
	if err != nil {
		return err
	}
	panes, err := a.panes()
	if err != nil {
		return err
	}
	for _, p := range panes {
		if p.Pi && within(p.Path, w.Path) {
			return a.jump(p.ID)
		}
	}
	if _, err := exec.LookPath("pi"); err != nil {
		return fmt.Errorf("pi not found on PATH")
	}
	session, err := a.workspaceSession(w)
	if err != nil {
		return err
	}
	return a.openSession(w, session, "pi", "--continue", "--name", w.Name)
}

func (a *app) shell(target string) error {
	if strings.HasPrefix(target, "%") {
		p, err := a.paneInfo(target)
		if err != nil {
			return err
		}
		path, err := a.git(p.Path, "rev-parse", "--show-toplevel")
		if err != nil {
			path = p.Path
		}
		return a.openSession(workspace{Path: path}, p.SessionID)
	}
	w, err := a.workspaceInfo(target)
	if err != nil {
		return err
	}
	session, err := a.workspaceSession(w)
	if err != nil {
		return err
	}
	return a.openSession(w, session)
}

func (a *app) remove(target string) error {
	path, stopPane, label := target, "", ""
	if strings.HasPrefix(target, "%") {
		p, err := a.paneInfo(target)
		if err != nil {
			return err
		}
		path, stopPane, label = p.Path, p.ID, p.label()
	}
	w, err := a.workspaceInfo(path)
	if err != nil {
		return err
	}
	if err := a.checkRemovable(w, stopPane); err != nil {
		return err
	}
	question := "Remove "
	if stopPane != "" {
		question = "Stop Pi in " + label + ", then remove "
	}
	answer, err := a.ask(question+w.Path+" and branch "+w.Name+"? Type "+w.Name+" to confirm: ", "type the name | esc back")
	if errors.Is(err, Err) {
		return nil
	}
	if err != nil || answer != w.Name {
		return err
	}
	// Re-resolve branch conventions and recheck state, other panes and files
	// after confirmation, before stopping anything or deleting any data.
	w, err = a.workspaceInfo(w.Path)
	if err != nil {
		return err
	}
	if err := a.checkRemovable(w, stopPane); err != nil {
		return err
	}
	// Do not start subsequent subprocesses inside a deleted directory. Keep
	// the caller's cwd for unrelated removals (and hence Ctrl-N's project).
	if within(a.dir, w.Path) {
		a.dir = w.Main
	}
	if stopPane != "" {
		// Keep the pane until Git finishes: deleting the popup's own last pane
		// would terminate the action mid-delete. Failure leaves a usable shell.
		if err := a.run("tmux", "respawn-pane", "-k", "-t", stopPane, "-c", w.Main, "--", a.option("default-shell", "/bin/sh"), ";",
			"set-option", "-pu", "-t", stopPane, "@agent_name", ";",
			"set-option", "-pu", "-t", stopPane, "@agent_state", ";",
			"set-option", "-pu", "-t", stopPane, "@agent_session", ";",
			"set-option", "-pu", "-t", stopPane, "@agent_since"); err != nil {
			return err
		}
		if err := a.checkRemovable(w, ""); err != nil {
			return err
		}
	}
	if err := a.runGit(w.Main, "worktree", "remove", w.Path); err != nil {
		return err
	}
	if err := a.runGit(w.Main, "branch", "-d", w.Name); err != nil {
		return err
	}
	if stopPane != "" {
		return a.run("tmux", "kill-pane", "-t", stopPane)
	}
	return nil
}

func (a *app) newSession() (outcome, error) {
	query, err := a.prompt([]string{"--prompt=Session name > ", "--ghost=name or name@base-revision",
		"--footer=enter create | esc back",
		"--bind=enter:transform:if [ -n {q} ]; then echo accept-or-print-query; fi"})
	if errors.Is(err, Err) {
		return backToList, nil
	}
	if err != nil {
		return backToList, err
	}
	return a.createSession(query)
}

func (a *app) createSession(query string) (outcome, error) {
	// Branch names here cannot contain @, so it separates the base revision.
	name, base, _ := strings.Cut(query, "@")
	if base == "" {
		base = "HEAD"
	}
	if !validName.MatchString(name) {
		return backToList, fmt.Errorf("use letters, digits, _ or -, starting with a letter or digit")
	}
	for _, command := range []string{"git", "tmux", "pi"} {
		if _, err := exec.LookPath(command); err != nil {
			return backToList, fmt.Errorf("%s not found on PATH", command)
		}
	}
	if _, err := a.output("git", "check-ref-format", "--branch", name); err != nil {
		return backToList, fmt.Errorf("invalid branch name: %s", name)
	}
	if inside, err := a.git(a.dir, "rev-parse", "--is-inside-work-tree"); err != nil || inside != "true" {
		return backToList, fmt.Errorf("the current pane is not in a Git worktree")
	}
	if _, err := a.git(a.dir, "rev-parse", "--verify", "--quiet", base+"^{commit}"); err != nil {
		return backToList, fmt.Errorf("unknown base revision: %s", base)
	}
	if _, err := a.output("tmux", "has-session", "-t", "="+name); err == nil {
		return backToList, fmt.Errorf("tmux session already exists: %s", name)
	}
	if _, err := a.git(a.dir, "show-ref", "--verify", "--quiet", "refs/heads/"+name); err == nil {
		return backToList, fmt.Errorf("branch already exists: %s", name)
	}
	main, err := a.mainWorktree(a.dir)
	if err != nil {
		return backToList, err
	}
	path := managedPath(main, name)
	if _, err := os.Lstat(path); !os.IsNotExist(err) {
		return backToList, fmt.Errorf("worktree path already exists or is inaccessible: %s", path)
	}
	if err := a.runGit(a.dir, "worktree", "add", "-b", name, path, base); err != nil {
		return backToList, err
	}
	result := closePopup
	hook := filepath.Join(main, ".pi", "worktree-setup")
	if info, err := os.Stat(hook); err == nil && !info.IsDir() && info.Mode()&0111 != 0 {
		runHook := func(cmd *exec.Cmd) error {
			cmd.Dir, cmd.Stdin, cmd.Stdout, cmd.Stderr = path, os.Stdin, a.out, a.errOut
			return cmd.Run()
		}
		err := runHook(a.command(hook, main))
		if errors.Is(err, syscall.ENOEXEC) {
			// Bash previously ran executable text hooks without a shebang.
			err = runHook(a.command("bash", hook, main))
		}
		if err != nil {
			if a.ctx.Err() != nil {
				return backToList, a.ctx.Err()
			}
			fmt.Fprintf(a.errOut, "pimux: worktree setup hook failed; continuing with %s\n", path)
			result = closeWithWarning
		}
	}
	if err := a.run("tmux", "new-session", "-d", "-s", name, "-c", path, "--", "pi", "--name", name); err != nil {
		// Only roll back what we just created, and never force deletion.
		if cleanup := a.runGit(a.dir, "worktree", "remove", path); cleanup == nil {
			_ = a.runGit(a.dir, "branch", "-d", name)
		}
		return backToList, fmt.Errorf("could not create tmux session: %s: %w", name, err)
	}
	// Run from a plain shell rather than a pane, there is no client to move.
	if os.Getenv("TMUX") == "" {
		return result, nil
	}
	if err := a.run("tmux", "switch-client", "-t", "="+name); err != nil {
		return closeWithWarning, err
	}
	return result, nil
}

func (a *app) project(path string) string {
	if match := managedDirectory.FindStringSubmatch(path); match != nil {
		return filepath.Base(match[1])
	}
	root, err := a.git(path, "rev-parse", "--show-toplevel")
	if err == nil {
		path = root
	}
	return filepath.Base(path)
}

// The scope file holds the main worktree the list is narrowed to, or nothing
// for every project. It lives beside the snapshot, so it lasts as long as the
// popup and never becomes stale state on disk.
func (a *app) scope() string {
	main, err := os.ReadFile(os.Getenv("PIMUX_SCOPE_FILE"))
	if err != nil {
		return ""
	}
	return string(main)
}

func (a *app) listPrompt() string {
	main := a.scope()
	if main == "" {
		return "pimux > "
	}
	// The prompt goes through fzf's change-prompt action, whose argument ends
	// at a closing parenthesis.
	return "pimux/" + strings.NewReplacer("(", "", ")", "").Replace(filepath.Base(main)) + " > "
}

func (a *app) rows() (string, error) {
	panes, err := a.panes()
	if err != nil {
		return "", err
	}
	var rows []row
	scope := a.scope()
	dirs := map[string]bool{a.dir: true}
	now := time.Now()
	for _, p := range panes {
		dirs[p.Path] = true
		if !p.Pi {
			continue
		}
		if scope != "" {
			// Another repository can be checked out inside the project's
			// directory, so compare main worktrees rather than paths.
			if main, err := a.mainWorktree(p.Path); err != nil || main != scope {
				continue
			}
		}
		title := p.Title
		if p.State == wait {
			if screen, err := a.output("tmux", "capture-pane", "-p", "-t", p.ID); err == nil {
				if question := promptQuestion(screen); question != "" {
					title = question
				}
			}
		}
		r := makeRow(p.ID, p.Session, p.Location, a.project(p.Path), p.State, "", stateAge(p.Since, now), title)
		if since, err := strconv.ParseInt(p.Since, 10, 64); err == nil && since > 0 {
			r.Since = since
		}
		rows = append(rows, r)
	}
	// Git remains the registry. No persistent index of projects or sessions.
	mains := make(map[string]bool)
	if scope != "" {
		mains[scope] = true
	} else {
		for dir := range dirs {
			main, err := a.mainWorktree(dir)
			if err == nil {
				mains[main] = true
			}
		}
	}
	for main := range mains {
		trees, err := a.worktrees(main)
		if err != nil {
			return "", err
		}
		for _, tree := range trees {
			if !validName.MatchString(tree.Branch) || tree.Path != managedPath(main, tree.Branch) {
				continue
			}
			if info, err := os.Stat(tree.Path); err != nil || !info.IsDir() {
				continue
			}
			active := false
			for _, p := range panes {
				if p.Pi && within(p.Path, tree.Path) {
					active = true
					break
				}
			}
			if active {
				continue
			}
			// A stopped workspace has no live state to age, so date it by its
			// last commit: that is how stale the branch itself is.
			committed, _ := a.git(main, "log", "-1", "--format=%ct", "refs/heads/"+tree.Branch)
			w := workspace{Path: tree.Path, Main: main, Name: tree.Branch}
			r := makeRow(tree.Path, tree.Branch, "-", filepath.Base(main), "stopped",
				a.removability(w, panes), stateAge(committed, now), "")
			if since, err := strconv.ParseInt(committed, 10, 64); err == nil && since > 0 {
				r.Since = since
			}
			rows = append(rows, r)
		}
	}
	sort.Slice(rows, func(i, j int) bool {
		if rows[i].Rank != rows[j].Rank {
			return rows[i].Rank < rows[j].Rank
		}
		if rows[i].Since != rows[j].Since {
			return rows[i].Since > rows[j].Since
		}
		if rows[i].Display != rows[j].Display {
			return rows[i].Display < rows[j].Display
		}
		return rows[i].ID < rows[j].ID
	})
	var text strings.Builder
	for _, r := range rows {
		fmt.Fprintf(&text, "%d%s%s%s%s\n", r.Rank, sep, r.ID, sep, r.Display)
	}
	return text.String(), nil
}

func (a *app) terminalWidth() int {
	if width, err := strconv.Atoi(os.Getenv("COLUMNS")); err == nil && width > 0 {
		return width
	}
	// The popup's controlling tty has the actual size, even when stdout and
	// stderr are captured for an action's failure screen.
	if tty, err := os.Open("/dev/tty"); err == nil {
		defer tty.Close()
		cmd := a.command("tput", "cols")
		cmd.Stdin = tty
		if out, err := cmd.Output(); err == nil {
			if width, err := strconv.Atoi(strings.TrimSpace(string(out))); err == nil && width > 0 {
				return width
			}
		}
	}
	return 80
}

func (a *app) prompt(options []string) (string, error) {
	args := append([]string{"--disabled", "--reverse", "--info=hidden", "--no-separator"}, options...)
	cmd := a.command("fzf", args...)
	cmd.Stderr = a.errOut
	out, err := cmd.Output() // nil stdin is /dev/null; fzf reads keys from /dev/tty
	if exitCode(err) == 130 {
		return "", Err
	}
	return strings.TrimRight(string(out), "\r\n"), err
}

func (a *app) ask(question, footer string) (string, error) {
	return a.prompt([]string{"--header=" + wrap(question, a.terminalWidth()-4),
		"--prompt=> ", "--footer=" + footer, "--bind=enter:accept-or-print-query"})
}

// Reports whether the snapshot changed, so an unchanged list is never redrawn.
func (a *app) writeRows(path string) (bool, error) {
	before, err := os.ReadFile(path)
	if err != nil {
		return false, err
	}
	after, err := a.rows()
	if err != nil {
		return false, err
	}
	if string(before) == after {
		return false, nil
	}
	// Atomic replacement avoids showing fzf a partial snapshot. The temporary
	// file is alongside the old one so rename stays on the same filesystem.
	next, err := os.CreateTemp(filepath.Dir(path), filepath.Base(path)+".*")
	if err != nil {
		return false, err
	}
	defer os.Remove(next.Name())
	_, writeErr := io.WriteString(next, after)
	closeErr := next.Close()
	if writeErr != nil {
		return false, writeErr
	}
	if closeErr != nil {
		return false, closeErr
	}
	if err := a.ctx.Err(); err != nil {
		return false, err
	}
	if err := os.Rename(next.Name(), path); err != nil {
		return false, err
	}
	return true, nil
}

func (a *app) refresh() error {
	changed, err := a.writeRows(os.Getenv("PIMUX_ROWS_FILE"))
	if err != nil || !changed {
		return err
	}
	_, err = fmt.Fprintln(a.out, `reload-sync(cat "$PIMUX_ROWS_FILE")`)
	return err
}

// Narrow the list to the invoking pane's project, or widen it again. Outside
// a repository there is no project to narrow to, so the list stays as it is.
func (a *app) toggleScope() error {
	path := os.Getenv("PIMUX_SCOPE_FILE")
	current, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	next := ""
	if len(current) == 0 {
		if next, err = a.mainWorktree(a.dir); err != nil {
			return nil
		}
	}
	if err := os.WriteFile(path, []byte(next), 0600); err != nil {
		return err
	}
	if _, err := a.writeRows(os.Getenv("PIMUX_ROWS_FILE")); err != nil {
		return err
	}
	_, err = fmt.Fprintf(a.out, "reload-sync(cat \"$PIMUX_ROWS_FILE\")+change-prompt(%s)\n", a.listPrompt())
	return err
}

func (a *app) pick() (string, error) {
	dir, err := os.MkdirTemp("", "pimux-list.*")
	if err != nil {
		return "", err
	}
	defer os.RemoveAll(dir)
	path := filepath.Join(dir, "rows")
	rows, err := a.rows()
	if err != nil {
		return "", err
	}
	if err := os.WriteFile(path, []byte(rows), 0600); err != nil {
		return "", err
	}
	// Every project until Ctrl-P narrows the list to the invoking project.
	scope := filepath.Join(dir, "scope")
	if err := os.WriteFile(scope, nil, 0600); err != nil {
		return "", err
	}
	input, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer input.Close()
	cmd := a.command("fzf", "--ansi", "--delimiter="+sep, "--with-nth=3", "--no-sort", "--reverse",
		"--info=inline-right", "--track", "--id-nth=2",
		"--bind=every(1),ctrl-r:bg-transform("+shellQuote(a.exe)+" list --refresh)",
		"--bind=ctrl-p:bg-transform("+shellQuote(a.exe)+" list --scope)",
		"--expect=ctrl-n,ctrl-o,ctrl-x,ctrl-d",
		"--footer=enter jump/resume | ctrl-n new | ctrl-p project | ctrl-o shell | ctrl-x stop | ctrl-d remove",
		"--prompt="+a.listPrompt())
	cmd.Env = append(cmd.Environ(), "PIMUX_ROWS_FILE="+path, "PIMUX_SCOPE_FILE="+scope)
	cmd.Stdin, cmd.Stderr = input, a.errOut
	out, err := cmd.Output()
	// Ctrl-N on an empty list returns 1 but still prints its expected key.
	if exitCode(err) == 1 {
		err = nil
	} else if exitCode(err) == 130 {
		return "", Err
	}
	return strings.TrimRight(string(out), "\r\n"), err
}

func (a *app) clear() { fmt.Fprint(a.out, "\x1b[H\x1b[2J") }

func (a *app) pause(message, footer string) error {
	a.clear()
	fmt.Fprint(a.out, message)
	cmd := a.command("fzf", "--disabled", "--no-input", "--reverse", "--info=hidden", "--no-separator",
		"--height=2", "--footer="+footer, "--bind=enter:abort")
	err := cmd.Run()
	if exitCode(err) == 130 {
		return nil
	}
	return err
}

func (a *app) list() error {
	for a.ctx.Err() == nil {
		selected, err := a.pick()
		if errors.Is(err, Err) || (err == nil && selected == "") {
			return nil
		}
		if err != nil {
			return err
		}
		key, selection, _ := strings.Cut(selected, "\n")
		target := ""
		if fields := strings.Split(selection, sep); len(fields) >= 3 {
			target = fields[1]
		}
		if key != "ctrl-n" && target == "" {
			return nil
		}
		action := map[string]string{"ctrl-n": "new", "ctrl-o": "shell", "ctrl-x": "stop", "ctrl-d": "remove"}[key]
		if action == "" {
			action = "resume"
			if strings.HasPrefix(target, "%") {
				action = "jump"
			}
		}
		a.clear()
		// Keep a fresh error copy per action without pipes, tee, or temp files.
		// exec.Cmd waits for its output copying before an error is displayed.
		var captured bytes.Buffer
		child := *a
		child.errOut = io.MultiWriter(a.errOut, &captured)
		var result outcome
		if action == "new" {
			result, err = child.newSession()
		} else {
			result, err = child.action(action, target)
		}
		a.dir = child.dir
		if a.ctx.Err() != nil {
			return a.ctx.Err()
		}
		if err != nil {
			fmt.Fprintln(child.errOut, "pimux:", err)
		}
		if result == backToList && err == nil {
			continue
		}
		if result == closePopup && err == nil {
			return nil
		}
		footer := "enter/esc back to list"
		if result == closeWithWarning {
			footer = "enter/esc close"
		}
		if err := a.pause(captured.String(), footer); err != nil {
			return err
		}
		if result == closeWithWarning {
			return nil
		}
	}
	return a.ctx.Err()
}
