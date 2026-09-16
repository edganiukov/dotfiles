# pimux

`prefix + a` opens a popup of running Pi panes and stopped managed workspaces.
The list checks for updates in the background every second and redraws only
when something changes, preserving your query and selected row.

| Key | Action |
| --- | --- |
| Enter | Jump to a running Pi pane or resume a stopped workspace |
| Ctrl-N | Create a new session, even when the list is empty or the filter has no matches |
| Ctrl-O | Open a shell window in the selected agent's worktree |
| Ctrl-X | Stop the selected Pi pane, after confirmation |
| Ctrl-D | Remove the selected stopped workspace and branch, after safety checks and confirmation |
| Ctrl-R | Refresh immediately |
| Esc | Close the popup; from any prompt, go back to the list instead |

Each row shows state, tmux session, window.pane, project, status, how long
that status has held, and a title: for a blocked agent, the question it is
waiting on; otherwise pi's own session name when it differs from the tmux
session. A managed session uses one name for its branch, worktree, tmux
session and pi session, so the name appears once; the project column is the
main repo, not the worktree directory (whose basename would just repeat the
name).

The age is measured from when the state last changed (`done 40m` is forty
minutes waiting on you), stamped by the pi extension as `@agent_since`.
tmux's own activity clock would not do: it ticks on any output, including
pi's spinner. Sessions started before this stamp existed show no age.

The popup only closes when an action takes you somewhere else (jump, resume,
shell, new). Everything that leaves you where you are returns to the list:
Esc or a declined answer on a confirmation, a completed stop or remove (the row
simply disappears), and a failed action after its error has been shown.

An action's output (git's "Preparing worktree...", tmux messages) streams to
the popup as it runs. If the action fails, that output is shown again on a
cleared screen so it is not lost under the list. Confirmation questions are
folded to the popup's width rather than cut off, with your answer on its own
input line beneath them.

## Create

Press **Ctrl-N**, enter a name, and press Enter to create it. **Esc** returns
to the session list; Enter with an empty name stays in the name prompt.
Creation uses the **invoking pane's working directory**, not the selected agent's project.
It must be inside a Git worktree. For a name such as `fix-auth`:

- Create branch `fix-auth` from the invoking worktree's current `HEAD`.
- Check it out at `<main-repo>-worktrees/fix-auth`, outside the source tree.
  Invoking from a linked worktree uses the same location.
- Run the repo's setup hook, if any (see below).
- Create tmux session `fix-auth` in that worktree and run `pi --name fix-auth`.
- Switch to the new session.

Uncommitted changes are left in the source worktree, not copied. Names may
contain ASCII letters, digits, `_` and `-`, starting with a letter or digit,
and must be valid Git branch names. Existing branches, paths and tmux sessions
are rejected, never overwritten. If tmux session creation fails, the new
worktree and branch are removed without forcing deletion.

### Setup hook

A fresh worktree has none of the gitignored state the source has: no
`node_modules`, `.env`, `.direnv`. If `<main-repo>/.pi/worktree-setup` exists
and is executable, it runs inside the new worktree with the **main worktree
path as its only argument**, before Pi starts. For example:

```sh
#!/usr/bin/env bash
set -e
cp "$1/.env" .env
npm ci
```

A failing hook does not remove the worktree or branch, since the code itself
is intact; the error stays on screen and the session still opens so you can
fix it there. Only the main worktree's hook is used, so it cannot be changed by
whatever `HEAD` happens to be checked out.

## Resume and shells

Git's worktree records are the registry. Stopped workspaces are discovered in
the invoking repository and repositories with a directory open in tmux. To
find a workspace from a project no longer open in tmux, open the popup from
that repository. There is no separate persistent session database.

Managed workspaces must have the path `<main-repo>-worktrees/<name>` and a
matching branch `<name>`. This also discovers workspaces created by earlier
versions of the plugin. Renamed branches or moved worktrees need manual Git
management.

Enter on a stopped workspace runs `pi --continue --name <name>` there,
continuing the most recent saved Pi conversation for that working directory.
It reuses a same-named tmux session containing a shell in the workspace, or
creates a new session. An unrelated same-named tmux session is never reused.

Ctrl-O opens a normal tmux shell window at the worktree root. For a stopped
workspace, it can create a shell-only tmux session without starting Pi.
Running Pi panes outside Git also support this shortcut, using their cwd.

## Stop and remove

Ctrl-X asks for confirmation and closes **only the selected Pi pane**. It
keeps shell windows, the worktree, and the branch. Closing the last pane also
closes its tmux session, subject to tmux's normal detach behavior. The
confirmation names the tmux session (and the pi session, if it differs), not
the bare pane id.

Ctrl-D is a separate, destructive action. It refuses removal if:

- Any tmux pane is still in the workspace or a subdirectory, including shells.
- There are uncommitted, untracked, or ignored files. This protects local
  configuration too; remove build products manually before cleanup.
- The workspace branch has commits not merged into the main checkout's current
  `HEAD`, or the workspace no longer follows the managed path/branch convention.

Type the workspace name to confirm. Checks run again after confirmation, and
Git removal/deletion never uses force. Git worktree locks are respected.
Separately stored Pi conversation history is not deleted.

## Indicators

Icons use plain Unicode:
`▢` idle/stopped, `◌` busy, `✶` done, and `◆` waiting. No Nerd Font is needed.
Colours are yellow for busy, green for done/idle/stopped, and red for waiting
(including the global blocked notice).
Tab indicators appear before the window label, separated by a single space.

`#{pimux_blocked}` in `status-right` shows **◆ N blocked** when any Pi panes
on the tmux server need input, including panes in other sessions. It disappears
when none are blocked. A completed turn (`done`) is not counted as blocked.
Dead panes are excluded from both the list and indicators.

### Blocked detection and desktop notifications

`pi/extensions/tmux.ts` listens for Pi's `ui_prompt_start` /
`ui_prompt_end` events, which fire around **every** blocking `ctx.ui` prompt
raised by an extension (`select`, `confirm`, `input`, `editor`, `custom`). So
permission gates, review pickers, question tools and any future extension are
all flagged as waiting with no per-extension code. When the prompt ends, the
pane returns to whatever state it had before (a picker opened from an idle
session goes back to idle, not busy).

Each prompt also sends a desktop notification titled `<session> needs input`
with the prompt's title: `notify-send` on Linux (dunst), `osascript` on macOS.
Both are best-effort and silent if the tool is missing.

Pi's own built-in dialogs (`/login`, `/model`, trust prompts) do not emit these
events and are not flagged. Those are ones you open yourself, so you are
already looking at them; the point is catching prompts the agent raises
mid-task while you are elsewhere.

## Setup

Requires Bash, Git, tmux with popup support, **fzf 0.74+** (timer refresh and
row-ID tracking), and Pi with `--name` and `--continue` support.
Install `pi/extensions/tmux.ts` for state and session-name publishing,
including discovery when Pi runs as `node`. Other agents are ignored.

Existing options: `@pimux-key` (default `a`), `@pimux-width` (`50%`),
`@pimux-height` (`30%`), and `@pimux-{busy,done,wait}-{icon,style}`.
Put `#{pimux}` before the label in both window status formats, and
`#{pimux_blocked}` in `status-right`. The global notice updates with tmux's
`status-interval` (one second in these dotfiles). `@pimux-commands` and Claude
hooks are no longer supported.

Reload `tmux.conf` (`prefix + r` with these dotfiles) after updating.

## Tests

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tmux/plugins/pimux/tests -v
```

Tests use temporary repositories and an isolated tmux server, with Pi and fzf
stubbed. They do not touch existing tmux sessions or start a real agent.
