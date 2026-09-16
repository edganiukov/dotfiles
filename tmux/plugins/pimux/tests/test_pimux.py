"""Integration tests using temporary Git repositories and an isolated tmux server.

Run with: python3 -m unittest discover -s tmux/plugins/pimux/tests -v
Only pi, fzf, and client switching are stubbed; no real agent is started.
"""

import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest


PLUGIN = Path(__file__).resolve().parents[1]
TMUX = shutil.which("tmux")
SEP = "\x1f"


@unittest.skipUnless(TMUX and shutil.which("git"), "requires tmux and git")
class AgentsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="pimux-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo with 'quotes'"
        self.repo.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.socket = str(self.root / "tmux.sock")
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}", HOME=str(self.root),
                        TMPDIR=str(self.root), TEST_DIR=str(self.root), TEST_SOCKET=self.socket, REAL_TMUX=TMUX)
        for key in ("TMUX", "TMUX_PANE"):
            self.env.pop(key, None)
        self.executable("tmux", '''#!/usr/bin/env python3
import json, os, subprocess, sys
from pathlib import Path
args = sys.argv[1:]
root = Path(os.environ["TEST_DIR"])
if args[0] == "switch-client":
    (root / "switch.json").write_text(json.dumps(args))
    sys.exit(0)
if args[0] == "new-session" and os.environ.get("FAIL_NEW"):
    sys.exit(1)
if args[0] == "list-panes" and os.environ.get("FAIL_LIST_PANES"):
    sys.exit(1)
sys.exit(subprocess.call([os.environ["REAL_TMUX"], "-S", os.environ["TEST_SOCKET"], *args]))
''')
        self.executable("pi", '''#!/usr/bin/env python3
import json, os, subprocess, sys, time
from pathlib import Path
subprocess.check_call(["tmux", "set-option", "-p", "-t", os.environ["TMUX_PANE"], "@agent_name", "pi"])
Path(os.environ["TEST_DIR"], "pi.json").write_text(json.dumps({"args": sys.argv[1:], "cwd": os.getcwd()}))
time.sleep(600)
''')
        self.executable("fzf", '''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
root = Path(os.environ["TEST_DIR"])
if "--disabled" in sys.argv:
    # A line prompt (session name, stop/remove confirmation), not the list.
    (root / "name-fzf.json").write_text(json.dumps(sys.argv[1:]))
    def opt(name):  # the error pause has a footer but no prompt
        return next((a[len(name):] for a in sys.argv if a.startswith(name)), "")
    # The question lives in --header (folded to width); --prompt is just "> ".
    with open(root / "prompts", "a") as f:
        f.write(" ".join(opt("--header=").split()) + "\\n")
    with open(root / "footers", "a") as f:
        f.write(opt("--footer=") + "\\n")
    if os.environ.get("NEW_CANCEL"):
        sys.exit(130)
    print(os.environ["NEW_NAME"])
    sys.exit(0)
rows = sys.stdin.read()
(root / "rows").write_text(rows)
(root / "fzf.json").write_text(json.dumps(sys.argv[1:]))
count_file = root / "picker-count"
count = int(count_file.read_text()) + 1 if count_file.exists() else 1
count_file.write_text(str(count))
if os.environ.get("KEY_ONCE") and count > 1:
    sys.exit(130)
for row in rows.splitlines():
    if row.split("\x1f")[1] == os.environ.get("PICK"):
        print(os.environ.get("KEY", ""))
        print(row)
        sys.exit(0)
if "KEY" in os.environ:
    print(os.environ["KEY"])
    sys.exit(1)
sys.exit(130)
''')
        self.git("init", "-q", "-b", "main")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                 "commit", "-qm", "initial", "--allow-empty")
        self.tmux("-f", "/dev/null", "new-session", "-d", "-s", "origin",
                  "-c", str(self.repo), "sleep", "600")
        self.addCleanup(lambda: subprocess.run(
            [TMUX, "-S", self.socket, "kill-server"], capture_output=True))
        self.env["TMUX"] = f"{self.socket},0,0"
        self.env["TMUX_PANE"] = "%0"

    def executable(self, name, text):
        path = self.bin / name
        path.write_text(text)
        path.chmod(0o755)

    def git(self, *args, cwd=None):
        return subprocess.check_output(["git", "-C", str(cwd or self.repo), *args],
                                       text=True, stderr=subprocess.STDOUT).strip()

    def tmux(self, *args):
        return subprocess.check_output([TMUX, "-S", self.socket, *args], env=self.env,
                                       text=True, stderr=subprocess.STDOUT).strip()

    def run_script(self, script, name="", cwd=None, args=(), **env):
        return subprocess.run(["bash", str(PLUGIN / script), *args], input=name + "\n",
                              cwd=cwd or self.repo, env=dict(self.env, NEW_NAME=name, **env),
                              text=True, capture_output=True, timeout=10)

    def worktree(self, name):
        return Path(f"{self.repo}-worktrees") / name

    def action(self, action, target, answer="", **kwargs):
        return self.run_script("pimux-action.sh", answer, args=(action, str(target)), **kwargs)

    def create_task(self):
        result = self.run_script("pimux-new.sh", "task")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.wait_for_pi()
        return self.tmux("list-panes", "-t", "=task", "-F", "#{pane_id}")

    def wait_for_pi(self):
        for _ in range(100):
            if (self.root / "pi.json").exists():
                return json.loads((self.root / "pi.json").read_text())
            time.sleep(0.02)
        self.fail("Pi did not start")

    def stopped_task(self):
        pane = self.create_task()
        self.tmux("kill-pane", "-t", pane)
        (self.root / "pi.json").unlink()
        return self.worktree("task")

    def listed_ids(self, cwd=None):
        result = self.run_script("pimux-list.sh", cwd=cwd, args=("--rows",))
        self.assertEqual(result.returncode, 0, result.stderr)
        return [row.split(SEP)[1] for row in result.stdout.splitlines()]

    def assert_unchanged(self):
        self.assertEqual(self.git("branch", "--format=%(refname:short)"), "main")
        self.assertEqual(self.git("worktree", "list", "--porcelain").count("worktree "), 1)
        self.assertFalse(Path(f"{self.repo}-worktrees").exists())
        self.assertEqual(self.tmux("list-sessions", "-F", "#{session_name}"), "origin")
        self.assertEqual(list(self.root.glob("pimux-list.*")), [])

    def test_create_from_subdirectory_and_current_head(self):
        nested = self.repo / "nested"
        nested.mkdir()
        (nested / "dirty").write_text("uncommitted")
        self.git("checkout", "-qb", "source")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                 "commit", "-qm", "source commit", "--allow-empty")
        result = self.run_script("pimux-new.sh", "task-1", cwd=nested)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git("branch", "--show-current", cwd=self.worktree("task-1")), "task-1")
        self.assertEqual(self.git("rev-parse", "task-1"), self.git("rev-parse", "source"))
        self.assertTrue((nested / "dirty").exists())
        self.assertFalse((self.worktree("task-1") / "nested" / "dirty").exists())
        for _ in range(100):
            if (self.root / "pi.json").exists():
                break
            time.sleep(0.02)
        launched = json.loads((self.root / "pi.json").read_text())
        self.assertEqual(launched, {"args": ["--name", "task-1"], "cwd": str(self.worktree("task-1"))})
        self.assertEqual(json.loads((self.root / "switch.json").read_text()),
                         ["switch-client", "-t", "=task-1"])

    def test_create_from_linked_worktree_uses_same_parent(self):
        linked = self.root / "linked"
        self.git("worktree", "add", "-qb", "source", str(linked))
        result = self.run_script("pimux-new.sh", "task", cwd=linked)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.worktree("task") / ".git").is_file())

    def test_invalid_names_do_not_mutate(self):
        for name in ("", "bad name", "../escape", "topic/task", "-option", "a.b", "a:b", "$(touch bad)", "HEAD"):
            with self.subTest(name=name):
                result = self.run_script("pimux-new.sh", name)
                self.assertNotEqual(result.returncode, 0, result.stderr)
                self.assert_unchanged()

    def test_non_repository_does_not_mutate(self):
        result = self.run_script("pimux-new.sh", "task", cwd=self.root)
        self.assertNotEqual(result.returncode, 0)
        self.assert_unchanged()

    def test_existing_branch_is_not_reused(self):
        self.git("branch", "task")
        result = self.run_script("pimux-new.sh", "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.worktree("task").exists())
        self.assertFalse((self.root / "pi.json").exists())
        self.assertIn("branch already exists", result.stderr)

    def test_existing_directory_is_not_overwritten(self):
        self.worktree("task").mkdir(parents=True)
        marker = self.worktree("task") / "keep"
        marker.write_text("keep")
        result = self.run_script("pimux-new.sh", "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(marker.read_text(), "keep")
        self.assertEqual(self.git("branch", "--format=%(refname:short)"), "main")

    def test_dangling_symlink_is_not_overwritten(self):
        self.worktree("task").parent.mkdir()
        self.worktree("task").symlink_to(self.root / "missing")
        result = self.run_script("pimux-new.sh", "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(self.worktree("task").is_symlink())
        self.assertEqual(self.git("branch", "--format=%(refname:short)"), "main")

    def test_tmux_name_prefix_is_not_a_collision(self):
        self.tmux("new-session", "-d", "-s", "task-long", "sleep", "600")
        result = self.run_script("pimux-new.sh", "task")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.worktree("task").exists())

    def test_existing_tmux_session_is_not_reused(self):
        result = self.run_script("pimux-new.sh", "origin")
        self.assertNotEqual(result.returncode, 0)
        self.assert_unchanged()

    def write_hook(self, body, executable=True):
        hook = self.repo / ".pi" / "worktree-setup"
        hook.parent.mkdir(exist_ok=True)
        hook.write_text("#!/usr/bin/env bash\n" + body)
        if executable:
            hook.chmod(0o755)
        return hook

    def test_setup_hook_runs_in_new_worktree_with_source_argument(self):
        (self.repo / ".env").write_text("SECRET=1")
        self.write_hook('printf "%s\\n%s\\n" "$PWD" "$1" > hook-ran; cp "$1/.env" .env\n')
        # From a linked worktree too: the hook and its argument use the main worktree.
        linked = self.root / "linked"
        self.git("worktree", "add", "-qb", "source", str(linked))
        result = self.run_script("pimux-new.sh", "task", cwd=linked)
        self.assertEqual(result.returncode, 0, result.stderr)
        workspace = self.worktree("task")
        self.assertEqual((workspace / "hook-ran").read_text().splitlines(), [str(workspace), str(self.repo)])
        self.assertEqual((workspace / ".env").read_text(), "SECRET=1")
        # Ran before pi so the session starts in a usable tree.
        self.assertEqual(self.wait_for_pi()["cwd"], str(workspace))

    def test_setup_hook_failure_keeps_worktree_and_is_reported(self):
        self.write_hook("echo 'npm install exploded' >&2; exit 1\n")
        result = self.run_script("pimux-new.sh", "task")
        self.assertEqual(result.returncode, 2)
        self.assertIn("npm install exploded", result.stderr)
        self.assertIn("setup hook failed", result.stderr)
        self.assertTrue(self.worktree("task").exists())
        self.assertIn("task", self.git("branch", "--format=%(refname:short)"))
        # Still starts pi and switches: the code is intact, only setup needs attention.
        self.assertEqual(self.wait_for_pi()["args"], ["--name", "task"])
        self.assertTrue((self.root / "switch.json").exists())

    def test_setup_hook_failure_pauses_then_closes_not_back_to_list(self):
        # You already switched to the new session, so the popup must not
        # reappear over it: show the message, then close (exit 0).
        self.write_hook("exit 1\n")
        result = self.run_script("pimux-list.sh", "task", KEY="ctrl-n", KEY_ONCE="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / "picker-count").read_text(), "1")
        self.assertTrue(self.worktree("task").exists())
        # The pause is an fzf prompt so Esc works, and its footer says close.
        self.assertEqual(self.footers()[-1], "enter/esc close")

    def test_non_executable_or_missing_hook_is_ignored(self):
        self.write_hook("touch hook-ran\n", executable=False)
        result = self.run_script("pimux-new.sh", "task")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.worktree("task") / "hook-ran").exists())

    def test_tmux_creation_failure_rolls_back_worktree_and_branch(self):
        result = self.run_script("pimux-new.sh", "task", FAIL_NEW="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.worktree("task").exists())
        self.assertEqual(self.git("branch", "--format=%(refname:short)"), "main")
        self.assertEqual(self.git("worktree", "list", "--porcelain").count("worktree "), 1)

    def test_list_only_pi_and_jump_to_selected_pane(self):
        self.tmux("set-option", "-p", "-t", "%0", "@agent_state", "wait")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_name", "claude")
        pi_pane = self.tmux("new-window", "-d", "-P", "-F", "#{pane_id}", "sleep", "600")
        self.tmux("set-option", "-p", "-t", pi_pane, "@agent_name", "pi")
        self.tmux("set-option", "-p", "-t", pi_pane, "@agent_session", "my task")
        result = self.run_script("pimux-list.sh", PICK=pi_pane)
        self.assertEqual(result.returncode, 0, result.stderr)
        rows = (self.root / "rows").read_text().splitlines()
        self.assertEqual([r.split(SEP)[1] for r in rows], [pi_pane])
        self.assertIn("my task", rows[0])
        self.assertTrue((self.root / "switch.json").exists())
        self.assertEqual(self.tmux("display-message", "-p", "#{pane_id}"), pi_pane)

    def test_empty_list_can_create(self):
        result = self.run_script("pimux-list.sh", "task", KEY="ctrl-n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / "rows").read_text(), "")
        self.assertTrue(self.worktree("task").exists())

    def test_ctrl_n_ignores_the_selected_row(self):
        pane = self.create_task()
        result = self.run_script("pimux-list.sh", "another", PICK=pane, KEY="ctrl-n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.worktree("another").exists())
        self.assertTrue(self.worktree("task").exists())

    def test_escape_from_name_prompt_returns_to_list(self):
        result = self.run_script("pimux-list.sh", KEY="ctrl-n", KEY_ONCE="1", NEW_CANCEL="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / "picker-count").read_text(), "2")
        self.assert_unchanged()

    def test_name_prompt_uses_escape_to_cancel(self):
        result = self.run_script("pimux-new.sh", "unfinished", NEW_CANCEL="1")
        self.assertEqual(result.returncode, 130, result.stderr)
        args = json.loads((self.root / "name-fzf.json").read_text())
        self.assertIn("--footer=enter create | esc back", args)
        self.assertIn("--bind=enter:transform:if [ -n {q} ]; then echo accept-or-print-query; fi", args)
        self.assertFalse(any("blank to cancel" in arg for arg in args))
        self.assert_unchanged()

    def test_other_shortcuts_without_selection_do_not_mutate(self):
        for key in ("", "ctrl-o", "ctrl-x", "ctrl-d"):
            with self.subTest(key=key):
                result = self.run_script("pimux-list.sh", KEY=key)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assert_unchanged()

    def test_cancel_list_does_not_mutate(self):
        result = self.run_script("pimux-list.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_unchanged()

    def test_binding_opens_in_current_directory_without_empty_guard(self):
        result = self.run_script("pimux.tmux")
        self.assertEqual(result.returncode, 0, result.stderr)
        binding = next(line for line in self.tmux("list-keys", "-T", "prefix").splitlines()
                       if line.split()[3] == "a")
        self.assertIn("display-popup", binding)
        self.assertIn('-d "#{pane_current_path}"', binding)
        self.assertNotIn("if-shell", binding)

    def test_status_icons_match_list(self):
        self.tmux("set-option", "-g", "window-status-format", "#{pimux}")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_name", "pi")
        self.run_script("pimux.tmux")
        for state, icon in (("wait", "▲"), ("busy", "◌"), ("done", "◉"), ("", "▢")):
            with self.subTest(state=state):
                self.tmux("set-option", "-p", "-t", "%0", "@agent_state", state)
                result = self.run_script("pimux-list.sh")
                self.assertEqual(result.returncode, 0, result.stderr)
                rows = (self.root / "rows").read_text().splitlines()
                self.assertIn(icon, rows[0])
                self.assertNotIn(f"({icon})", rows[0])
                self.assertEqual(len(rows), 1)
                status = self.tmux("display-message", "-p", "#{E:window-status-format}tab")
                if state:
                    self.assertNotIn(f"({icon})", status)
                    self.assertTrue(status.endswith(f"{icon}#[default] tab"))
                else:
                    self.assertEqual(status, "tab")

    def test_config_places_indicator_before_tab_label(self):
        options = ("window-status-format", "window-status-current-format")
        config = (PLUGIN.parents[2] / "tmux.conf").read_text()
        for line in config.splitlines():
            if any(line.startswith(f"setw -g {option} ") for option in options):
                _, _, option, value = line.split(maxsplit=3)
                self.tmux("set-option", "-g", option, value.strip('"'))
        self.tmux("rename-window", "pi")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_name", "pi")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_state", "busy")
        # Keep the agent in a background pane so the current-tab indicator shows.
        self.tmux("split-window", "-h", "sleep", "600")
        self.run_script("pimux.tmux")
        for option in options:
            with self.subTest(option=option):
                status = self.tmux("display-message", "-p", f"#{{E:{option}}}")
                self.assertIn("◌#[default] 0:pi", status)
                self.assertNotIn("(◌)", status)

    def test_status_ignores_non_pi_state(self):
        self.tmux("set-option", "-g", "window-status-format", "#{pimux}")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_state", "wait")
        self.run_script("pimux.tmux")
        self.assertEqual(self.tmux("display-message", "-p", "#{E:window-status-format}"), "")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_name", "pi")
        self.assertIn("▲", self.tmux("display-message", "-p", "#{E:window-status-format}"))

    def test_current_status_skips_active_pi_pane(self):
        self.tmux("set-option", "-g", "window-status-current-format", "#{pimux}")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_name", "pi")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_state", "wait")
        self.run_script("pimux.tmux")
        self.assertEqual(self.tmux("display-message", "-p", "#{E:window-status-current-format}"), "")
        self.tmux("split-window", "-h", "sleep", "600")
        self.assertIn("▲", self.tmux("display-message", "-p", "#{E:window-status-current-format}"))

    def test_stopped_workspaces_are_found_without_a_registry(self):
        workspace = self.stopped_task()
        # The source repo remains open in tmux, so another cwd still finds it.
        self.assertEqual(self.listed_ids(cwd=self.root), [str(workspace)])
        self.git("worktree", "add", "-qb", "unmanaged", str(self.root / "unmanaged"))
        self.assertEqual(self.listed_ids(), [str(workspace)])

    def test_running_workspace_is_not_listed_twice(self):
        pane = self.create_task()
        self.assertEqual(self.listed_ids(), [pane])

    def rows_text(self, cwd=None):
        result = self.run_script("pimux-list.sh", cwd=cwd, args=("--rows",))
        self.assertEqual(result.returncode, 0, result.stderr)
        return [line.split(SEP)[2] for line in result.stdout.splitlines()]

    def test_row_does_not_repeat_the_session_name(self):
        # A managed session uses one name for branch, worktree, tmux session and
        # pi session; the row should say it once and name the project instead.
        pane = self.create_task()
        self.tmux("set-option", "-p", "-t", pane, "@agent_session", "task")
        # The project column is the main repo (truncated to fit), not the
        # worktree dir, whose basename would just be "task" again.
        project = self.repo.name[:13] + "…"
        [row] = self.rows_text()
        self.assertEqual(row.count("task"), 1, row)
        self.assertIn(project, row)
        self.assertNotIn("pi ", row.split("task")[0])
        # The stopped row follows the same shape.
        self.tmux("kill-pane", "-t", pane)
        [row] = self.rows_text()
        self.assertEqual(row.count("task"), 1, row)
        self.assertIn(project, row)
        self.assertIn("stopped", row)
        self.assertTrue(row.startswith("▢ "), row)

    def test_row_shows_pi_session_name_only_when_it_differs(self):
        pane = self.create_task()
        self.tmux("set-option", "-p", "-t", pane, "@agent_session", "Refactor auth")
        [row] = self.rows_text()
        self.assertIn("Refactor auth", row)
        self.assertEqual(row.count("task"), 1)

    def test_row_shows_how_long_the_state_has_held(self):
        pane = self.create_task()
        now = int(time.time())
        for delta, shown in ((5, "5s"), (2700, "45m"), (7200, "2h"), (3 * 86400, "3d")):
            with self.subTest(age=shown):
                self.tmux("set-option", "-p", "-t", pane, "@agent_state", "done")
                self.tmux("set-option", "-p", "-t", pane, "@agent_since", str(now - delta))
                [row] = self.rows_text()
                self.assertRegex(row, rf"done\s+{shown}\b")
        # No stamp (pi predates it, or idle since start): no age, no error.
        self.tmux("set-option", "-pu", "-t", pane, "@agent_since")
        [row] = self.rows_text()
        plain = re.sub(r"\x1b\[[0-9;]*m", "", row)  # colour codes contain digits+m
        self.assertNotRegex(plain, r"\d+[smhd]\b")

    def paint_pi_screen(self, pane, *box):
        """Make a pane look like pi while a prompt is up: conversation, then the
        prompt widget in the box between two rules (question, choices, key
        hints), then the footer. The stub pi just sleeps, so we draw it."""
        screen = self.root / "screen"
        screen.write_text("I will push the branch now.\n\n──────────\n\n" + "\n".join(box) +
                          "\n\n──────────\n~/repo (task) • task\n↑430k ↓197k $82 50.9%/1.0M (auto)\n")
        return self.tmux("respawn-pane", "-k", "-t", pane, "bash", "-c", f"clear; cat {screen}; sleep 600")

    def test_blocked_row_shows_the_question_the_agent_is_waiting_on(self):
        pane = self.create_task()
        self.paint_pi_screen(pane, " Allow git push to origin?", "", " → Yes", "   No", "",
                             " ↑↓ navigate  enter select  escape/ctrl+c cancel")
        self.tmux("set-option", "-p", "-t", pane, "@agent_name", "pi")
        self.tmux("set-option", "-p", "-t", pane, "@agent_session", "Refactor auth")
        time.sleep(0.3)
        # Blocked: the last conversation line (the question) wins over the name.
        self.tmux("set-option", "-p", "-t", pane, "@agent_state", "wait")
        [row] = self.rows_text()
        self.assertIn("Allow git push to origin?", row)
        self.assertNotIn("Refactor auth", row)
        # Never the key hints, the choices, the conversation above, or the footer.
        for noise in ("navigate", "Yes", "push the branch", "430k", "~/repo"):
            self.assertNotIn(noise, row)
        # Not blocked: back to the session name.
        self.tmux("set-option", "-p", "-t", pane, "@agent_state", "busy")
        [row] = self.rows_text()
        self.assertIn("Refactor auth", row)
        self.assertNotIn("Allow?", row)

    def test_action_output_streams_to_the_screen(self):
        # git's "Preparing worktree" progress goes to stderr; it must reach the
        # terminal live, not be swallowed into the error capture.
        result = self.run_script("pimux-list.sh", "task", KEY="ctrl-n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Preparing worktree", result.stderr)
        self.assertEqual(list(self.root.glob("pimux-errors.*")), [], "capture file leaked")

    def test_resume_stopped_workspace_from_picker(self):
        workspace = self.stopped_task()
        result = self.run_script("pimux-list.sh", PICK=str(workspace))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.wait_for_pi(), {"args": ["--continue", "--name", "task"], "cwd": str(workspace)})
        self.assertEqual(self.git("worktree", "list", "--porcelain").count("worktree "), 2)

    def test_resume_running_workspace_jumps_without_duplicate(self):
        pane = self.create_task()
        result = self.action("resume", self.worktree("task"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.tmux("list-panes", "-s", "-t", "=task", "-F", "#{pane_id}"), pane)

    def test_shell_shortcut_opens_at_worktree_root(self):
        pane = self.create_task()
        result = self.run_script("pimux-list.sh", PICK=pane, KEY="ctrl-o")
        self.assertEqual(result.returncode, 0, result.stderr)
        windows = self.tmux("list-windows", "-t", "=task", "-F", "#{window_id}").splitlines()
        self.assertEqual(len(windows), 2)
        self.assertEqual(self.tmux("display-message", "-p", "-t", windows[-1], "#{pane_current_path}"),
                         str(self.worktree("task")))
        self.assertIn(pane, self.listed_ids())

    def test_shell_then_resume_reuses_workspace_session(self):
        workspace = self.stopped_task()
        result = self.action("shell", workspace)
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.action("resume", workspace)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.wait_for_pi()["args"], ["--continue", "--name", "task"])
        self.assertEqual(len(self.tmux("list-windows", "-t", "=task").splitlines()), 2)

    def test_resume_and_shell_refuse_unrelated_session_name_collision(self):
        workspace = self.stopped_task()
        self.tmux("new-session", "-d", "-s", "task", "-c", str(self.root), "sleep", "600")
        for action in ("resume", "shell"):
            with self.subTest(action=action):
                result = self.action(action, workspace)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("another directory", result.stderr)
        self.assertFalse((self.root / "pi.json").exists())

    def test_stop_preserves_shell_window_and_workspace(self):
        pane = self.create_task()
        self.action("shell", pane)
        marker = self.worktree("task") / "keep"
        marker.write_text("unfinished")
        result = self.run_script("pimux-list.sh", "y", PICK=pane, KEY="ctrl-x")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.tmux("list-panes", "-s", "-t", "=task").splitlines()), 1)
        self.assertEqual(marker.read_text(), "unfinished")
        self.assertIn("task", self.git("branch", "--format=%(refname:short)"))
        self.assertIn(str(self.worktree("task")), self.listed_ids())

    def prompts(self):
        path = self.root / "prompts"
        return path.read_text().splitlines() if path.exists() else []

    def footers(self):
        path = self.root / "footers"
        return path.read_text().splitlines() if path.exists() else []

    def test_prompt_question_is_folded_to_the_terminal_width(self):
        # fzf truncates a long --prompt at the popup edge, so the question goes
        # in --header, folded by the real terminal width read from /dev/tty
        # (stdout is captured and stderr tee'd, so tput would otherwise say 80).
        workspace = self.stopped_task()
        # Record the raw --header so we can see the fold, not the re-joined text.
        self.executable("fzf", '''#!/usr/bin/env python3
import os, sys
from pathlib import Path
for a in sys.argv:
    if a.startswith("--header="):
        Path(os.environ["TEST_DIR"], "raw-header").write_text(a[len("--header="):])
    if a.startswith("--prompt="):
        Path(os.environ["TEST_DIR"], "raw-prompt").write_text(a[len("--prompt="):])
sys.exit(130)
''')
        self.action("remove", workspace, COLUMNS="40")
        lines = (self.root / "raw-header").read_text().rstrip("\n").split("\n")
        self.assertGreater(len(lines), 1, "long question was not folded")
        self.assertLessEqual(max(len(l) for l in lines), 40 - 4)
        self.assertEqual(" ".join(" ".join(lines).split()),
                         f"Remove {workspace} and branch task? Type task to confirm:")
        # The input row has its own short prompt, so typing is on a new line.
        self.assertEqual((self.root / "raw-prompt").read_text(), "> ")

    def test_stop_prompt_names_the_session_not_the_pane_id(self):
        pane = self.create_task()
        self.tmux("set-option", "-p", "-t", pane, "@agent_session", "task")
        self.action("stop", pane)
        prompt = self.prompts()[-1]
        self.assertIn("Stop Pi in task?", prompt)
        self.assertNotIn(pane, prompt)
        self.assertNotIn("$", prompt)
        # A distinct pi session label is shown alongside the tmux session.
        self.tmux("set-option", "-p", "-t", pane, "@agent_session", "Refactor auth")
        self.action("stop", pane)
        self.assertIn("Stop Pi in task (Refactor auth)?", self.prompts()[-1])
        # Declining left everything running.
        self.assertIn(pane, self.listed_ids())

    def test_stop_declined_or_escaped_returns_to_list(self):
        pane = self.create_task()
        for how in ({"answer": ""}, {"answer": "n"}, {"NEW_CANCEL": "1"}):
            with self.subTest(how=how):
                result = self.action("stop", pane, **how)
                self.assertEqual(result.returncode, 130, result.stderr)
                self.assertIn(pane, self.listed_ids())

    def test_stop_confirmed_returns_to_list_without_the_row(self):
        pane = self.create_task()
        result = self.run_script("pimux-list.sh", "y", PICK=pane, KEY="ctrl-x", KEY_ONCE="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(pane, self.listed_ids())
        # The list was shown again after the stop, then Esc closed it.
        self.assertEqual((self.root / "picker-count").read_text(), "2")

    def test_stop_rejects_non_pi_panes(self):
        result = self.action("stop", "%0", "y")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no longer running", result.stderr)
        self.tmux("display-message", "-p", "-t", "%0", "#{pane_id}")

    def test_remove_requires_confirmation_then_removes_only_workspace(self):
        workspace = self.stopped_task()
        for how in ({"answer": ""}, {"answer": "wrong"}, {"NEW_CANCEL": "1"}):
            with self.subTest(how=how):
                result = self.action("remove", workspace, **how)
                self.assertEqual(result.returncode, 130, result.stderr)
                self.assertTrue(workspace.exists())
        result = self.run_script("pimux-list.sh", "task", PICK=str(workspace), KEY="ctrl-d", KEY_ONCE="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(workspace.exists())
        self.assertTrue(self.repo.exists())
        self.assertEqual(self.git("branch", "--format=%(refname:short)"), "main")
        self.assertEqual(self.listed_ids(), [])
        # Back to the (now empty) list after removal, then Esc closed it.
        self.assertEqual((self.root / "picker-count").read_text(), "2")

    def test_action_error_pauses_then_returns_to_list(self):
        workspace = self.stopped_task()
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                 "commit", "-qm", "unfinished", "--allow-empty", cwd=workspace)
        result = self.run_script("pimux-list.sh", "task", PICK=str(workspace), KEY="ctrl-d", KEY_ONCE="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / "picker-count").read_text(), "2")
        self.assertTrue(workspace.exists())
        # The error streams live to the screen (stderr) as it happens, and is
        # re-shown once on a cleared screen before an fzf pause (so Esc works,
        # unlike read -p) leads back to the list.
        self.assertEqual(result.stderr.count("not merged"), 1)
        self.assertEqual(result.stdout.count("not merged"), 1)
        self.assertNotIn("Press Enter", result.stdout)
        self.assertEqual(self.footers()[-1], "enter/esc back to list")
        self.assertEqual(list(self.root.glob("pimux-errors.*")), [], "error capture file leaked")

    def test_remove_refuses_unmerged_commits_then_allows_merged(self):
        workspace = self.stopped_task()
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                 "commit", "-qm", "unfinished", "--allow-empty", cwd=workspace)
        result = self.action("remove", workspace, "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not merged", result.stderr)
        self.assertTrue(workspace.exists())
        self.git("merge", "--ff-only", "task")
        result = self.action("remove", workspace, "task")
        self.assertEqual(result.returncode, 130, result.stderr)
        self.assertFalse(workspace.exists())

    def test_remove_refuses_untracked_staged_and_ignored_files(self):
        workspace = self.stopped_task()
        marker = workspace / "keep"
        for state in ("untracked", "staged", "ignored"):
            with self.subTest(state=state):
                marker.write_text("keep")
                if state == "staged":
                    self.git("add", "keep", cwd=workspace)
                elif state == "ignored":
                    (self.repo / ".git" / "info" / "exclude").write_text("keep\n")
                result = self.action("remove", workspace, "task")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("files", result.stderr)
                self.assertEqual(marker.read_text(), "keep")
                self.git("reset", "--quiet", cwd=workspace)
                marker.unlink()

    def test_remove_refuses_active_agents_and_shells_in_subdirectories(self):
        pane = self.create_task()
        result = self.action("remove", self.worktree("task"), "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("in use", result.stderr)
        self.tmux("kill-pane", "-t", pane)
        nested = self.worktree("task") / "nested"
        nested.mkdir()
        self.tmux("new-window", "-d", "-c", str(nested), "sleep", "600")
        result = self.action("remove", self.worktree("task"), "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("in use", result.stderr)

    def test_remove_fails_closed_if_tmux_pane_check_fails(self):
        workspace = self.stopped_task()
        result = self.action("remove", workspace, "task", FAIL_LIST_PANES="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not check active tmux panes", result.stderr)
        self.assertTrue(workspace.exists())
        self.assertIn("task", self.git("branch", "--format=%(refname:short)"))

    def test_remove_respects_git_worktree_lock(self):
        workspace = self.stopped_task()
        self.git("worktree", "lock", str(workspace))
        result = self.action("remove", workspace, "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(workspace.exists())
        self.assertIn("task", self.git("branch", "--format=%(refname:short)"))

    def test_remove_rechecks_for_changes_after_confirmation(self):
        workspace = self.stopped_task()
        real_git = shutil.which("git")
        self.executable("git", f'''#!/usr/bin/env python3
import os, sys
from pathlib import Path
root = Path(os.environ["TEST_DIR"])
if "status" in sys.argv:
    checked = root / "checked"
    if checked.exists():
        (Path(sys.argv[2]) / "new-work").write_text("keep")
    checked.touch()
os.execv({real_git!r}, [{real_git!r}, *sys.argv[1:]])
''')
        result = self.action("remove", workspace, "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((workspace / "new-work").read_text(), "keep")

    def test_resume_failure_preserves_existing_workspace(self):
        workspace = self.stopped_task()
        result = self.action("resume", workspace, FAIL_NEW="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(workspace.exists())
        self.assertIn("task", self.git("branch", "--format=%(refname:short)"))

    def test_remove_refuses_unmanaged_or_changed_branches(self):
        result = self.action("remove", self.repo, "main")
        self.assertNotEqual(result.returncode, 0)
        workspace = self.stopped_task()
        self.git("checkout", "-qb", "other", cwd=workspace)
        result = self.action("remove", workspace, "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("branch has changed", result.stderr)
        self.assertTrue(workspace.exists())

    def test_picker_refreshes_and_tracks_stable_row_ids(self):
        self.run_script("pimux-list.sh")
        args = json.loads((self.root / "fzf.json").read_text())
        self.assertIn("--track", args)
        self.assertIn("--id-nth=2", args)
        self.assertTrue(any("every(1),ctrl-r:bg-transform" in arg and "--refresh" in arg for arg in args))
        self.assertFalse(any("every(1),ctrl-r:reload-sync" in arg for arg in args))
        self.assertEqual(list(self.root.glob("pimux-list.*")), [])
        self.assertIn("--expect=ctrl-n,ctrl-o,ctrl-x,ctrl-d", args)
        self.assertIn("--footer=enter jump/resume | ctrl-n new | ctrl-o shell | ctrl-x stop | ctrl-d remove", args)
        self.assertFalse(any(arg.startswith("--header") for arg in args))

    def test_refresh_is_silent_until_rows_change(self):
        self.tmux("set-option", "-p", "-t", "%0", "@agent_name", "pi")
        snapshot = self.root / "snapshot"
        snapshot.write_text(self.run_script("pimux-list.sh", args=("--rows",)).stdout)
        before = snapshot.stat().st_mtime_ns
        result = self.run_script("pimux-list.sh", args=("--refresh",), PIMUX_ROWS_FILE=str(snapshot))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(snapshot.stat().st_mtime_ns, before)

        self.tmux("set-option", "-p", "-t", "%0", "@agent_state", "wait")
        result = self.run_script("pimux-list.sh", args=("--refresh",), PIMUX_ROWS_FILE=str(snapshot))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, 'reload-sync(cat "$PIMUX_ROWS_FILE")\n')
        self.assertIn("blocked", snapshot.read_text())
        result = self.run_script("pimux-list.sh", args=("--refresh",), PIMUX_ROWS_FILE=str(snapshot))
        self.assertEqual(result.stdout, "")
        self.assertEqual(list(self.root.glob("snapshot.*")), [])

    def test_refresh_handles_empty_list_transitions(self):
        snapshot = self.root / "snapshot"
        snapshot.write_text("")
        result = self.run_script("pimux-list.sh", args=("--refresh",), PIMUX_ROWS_FILE=str(snapshot))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_name", "pi")
        result = self.run_script("pimux-list.sh", args=("--refresh",), PIMUX_ROWS_FILE=str(snapshot))
        self.assertIn("reload-sync", result.stdout)
        self.assertIn("%0", snapshot.read_text())
        self.tmux("set-option", "-pu", "-t", "%0", "@agent_name")
        result = self.run_script("pimux-list.sh", args=("--refresh",), PIMUX_ROWS_FILE=str(snapshot))
        self.assertIn("reload-sync", result.stdout)
        self.assertEqual(snapshot.read_text(), "")

    def test_global_blocked_notice_counts_all_pi_sessions(self):
        self.assertEqual(self.run_script("pimux-status.sh").stdout, "")
        pane = self.create_task()
        self.tmux("set-option", "-p", "-t", pane, "@agent_state", "wait")
        # A stale non-Pi state must not count.
        self.tmux("set-option", "-p", "-t", "%0", "@agent_state", "wait")
        result = self.run_script("pimux-status.sh")
        self.assertIn("▲ 1 blocked", result.stdout)
        self.tmux("set-option", "-p", "-t", "%0", "@agent_name", "pi")
        self.assertIn("▲ 2 blocked", self.run_script("pimux-status.sh").stdout)
        self.tmux("set-option", "-p", "-t", pane, "@agent_state", "busy")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_state", "done")
        self.assertEqual(self.run_script("pimux-status.sh").stdout, "")

    def test_dead_pi_panes_do_not_count_as_running_or_blocked(self):
        pane = self.create_task()
        self.tmux("set-option", "-p", "-t", pane, "@agent_state", "wait")
        self.tmux("set-option", "-w", "-t", pane, "remain-on-exit", "on")
        pid = self.tmux("display-message", "-p", "-t", pane, "#{pane_pid}")
        os.kill(int(pid), 15)
        for _ in range(100):
            if self.tmux("display-message", "-p", "-t", pane, "#{pane_dead}") == "1":
                break
            time.sleep(0.02)
        self.assertEqual(self.run_script("pimux-status.sh").stdout, "")
        self.assertNotIn(pane, self.listed_ids())
        self.assertIn(str(self.worktree("task")), self.listed_ids())

    def test_global_notice_placeholder_is_installed(self):
        self.tmux("set-option", "-g", "status-right", "#{pimux_blocked}clock")
        self.run_script("pimux.tmux")
        status = self.tmux("show-option", "-gqv", "status-right")
        self.assertIn("pimux-status.sh", status)
        self.assertNotIn("#{pimux_blocked}", status)
        self.assertTrue(status.endswith("clock"))


if __name__ == "__main__":
    unittest.main()
