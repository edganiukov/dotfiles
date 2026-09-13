#!/usr/bin/env bash

# Run inside the agent popup, in the invoking pane's directory.
# A single name identifies the new branch, worktree, tmux session and pi session.

readonly plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$plugin_dir/pimux-common.sh"

# Reuse fzf's editor so Escape works immediately, without a custom key reader.
name="$(fzf --disabled --reverse --info=hidden --no-separator \
  --prompt='Session name > ' --footer='enter create | esc back' \
  --bind='enter:transform:if [ -n {q} ]; then echo accept-or-print-query; fi' \
  < /dev/null)" || exit "$?"

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
main="$(main_worktree "$PWD")" || fail "could not locate the main worktree"
worktree="$main-worktrees/$name"
if [ -e "$worktree" ] || [ -L "$worktree" ]; then
  fail "worktree path already exists: $worktree"
fi

git worktree add -b "$name" "$worktree" HEAD || exit 1

# A fresh worktree has none of the gitignored state the source has: no
# node_modules, .env, .direnv. The repo's own hook decides what to restore, run
# in the new worktree with the source worktree as its argument. Its failure is
# reported but does not undo the worktree, since the code itself is intact.
readonly hook="$main/.pi/worktree-setup"
if [ -x "$hook" ]; then
  if ! (cd "$worktree" && "$hook" "$main"); then
    printf 'pimux: worktree setup hook failed; continuing with %s\n' "$worktree" >&2
    setup_failed=true
  fi
fi

# Multiple command arguments let tmux exec pi directly, without shell parsing.
if ! tmux new-session -d -s "$name" -c "$worktree" -- pi --name "$name"; then
  # No agent was started. Remove only what we created, without forcing deletion.
  git worktree remove "$worktree" && git branch -d "$name"
  fail "could not create tmux session: $name"
fi

tmux switch-client -t "=$name"
[ "${setup_failed:-}" != true ] || exit 2
