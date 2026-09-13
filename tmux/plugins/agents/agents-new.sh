#!/usr/bin/env bash

# Run inside the agent popup, in the invoking pane's directory.
# A single name identifies the new branch, worktree, tmux session and pi session.

fail() {
  printf 'agents: %s\n' "$*" >&2
  exit 1
}

read -r -p "Session name (blank to cancel): " name || exit 0
[ -n "$name" ] || exit 0

# Use the same name everywhere without Git path separators or tmux's ./: syntax.
[[ $name =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]] ||
  fail "use letters, digits, _ or -, starting with a letter or digit"

for command in git tmux pi; do
  type "$command" >/dev/null 2>&1 || fail "$command not found on PATH"
done

git check-ref-format --branch "$name" >/dev/null 2>&1 || fail "invalid branch name: $name"
[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ] ||
  fail "the current pane is not in a Git worktree"

tmux has-session -t "=$name" 2>/dev/null && fail "tmux session already exists: $name"
git show-ref --verify --quiet "refs/heads/$name" && fail "branch already exists: $name"

# The first entry is the main worktree, even when invoked from a linked one.
# -z preserves spaces and other special characters in the repository path.
IFS= read -r -d '' main < <(git worktree list --porcelain -z) ||
  fail "could not locate the main worktree"
worktree="${main#worktree }-worktrees/$name"
if [ -e "$worktree" ] || [ -L "$worktree" ]; then
  fail "worktree path already exists: $worktree"
fi

git worktree add -b "$name" "$worktree" HEAD || exit 1

# Multiple command arguments let tmux exec pi directly, without shell parsing.
if ! tmux new-session -d -s "$name" -c "$worktree" -- pi --name "$name"; then
  # No agent was started. Remove only what we created, without forcing deletion.
  git worktree remove "$worktree" && git branch -d "$name"
  fail "could not create tmux session: $name"
fi

tmux switch-client -t "=$name"
