# tmux pi sessions

`prefix + a` opens a popup of running pi panes. Select one to jump to it, or
select **+ New pi session** and enter a name. The New entry is available even
when no pi sessions are running. Escape closes the list; a blank name cancels.

Creation uses the **invoking pane's working directory**, not the selected
agent's project. It must be inside a Git worktree. For a name such as `fix-auth`:

- Create branch `fix-auth` from the invoking worktree's current `HEAD`.
- Check it out at `<main-repo>-worktrees/fix-auth`, outside the source tree.
  Invoking from a linked worktree uses the same location.
- Create tmux session `fix-auth` in that worktree and run `pi --name fix-auth`.
- Switch to the new session.

Uncommitted changes are left in the source worktree, not copied. Names may
contain ASCII letters, digits, `_` and `-`, starting with a letter or digit,
and must be valid Git branch names. Existing branches, paths and tmux sessions
are rejected, never reused or overwritten. If tmux session creation fails,
the new worktree and branch are removed without forcing deletion.

Requires Bash, Git, tmux (with popup support), fzf, and pi with `--name` support.
Install `pi/extensions/tmux-agents.ts` for state and session-name publishing,
including discovery when pi runs as `node`. Other agents are ignored.

Icons use plain Unicode supported by the configured Terminus font:
`○` idle, `●` busy, `✓` done, `▲` waiting, and `+` new. No Nerd Font is needed.
Existing colors and state behavior are unchanged.

Existing tmux options are unchanged: `@agents-key` (default `a`),
`@agents-width` (`50%`), `@agents-height` (`30%`), and the
`@agents-{busy,done,wait}-{icon,style}` options. Put `#{agents}` in the window
status formats for indicators. `@agents-commands` and Claude hooks are no
longer supported.

Reload `tmux.conf` (`prefix + r` with these dotfiles) after updating.

## Tests

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tmux/plugins/agents/tests -v
```

Tests use temporary repositories and an isolated tmux server, with pi and fzf
stubbed. They do not touch existing tmux sessions or start a real agent.
