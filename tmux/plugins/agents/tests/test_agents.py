"""Integration tests using temporary Git repositories and an isolated tmux server.

Run with: python3 -m unittest discover -s tmux/plugins/agents/tests -v
Only pi, fzf, and client switching are stubbed; no real agent is started.
"""

import json
import os
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
        self.temp = tempfile.TemporaryDirectory(prefix="tmux-agents-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo with 'quotes'"
        self.repo.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.socket = str(self.root / "tmux.sock")
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}",
                        TEST_DIR=str(self.root), TEST_SOCKET=self.socket, REAL_TMUX=TMUX)
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
sys.exit(subprocess.call([os.environ["REAL_TMUX"], "-S", os.environ["TEST_SOCKET"], *args]))
''')
        self.executable("pi", '''#!/usr/bin/env python3
import json, os, sys, time
from pathlib import Path
Path(os.environ["TEST_DIR"], "pi.json").write_text(json.dumps({"args": sys.argv[1:], "cwd": os.getcwd()}))
time.sleep(600)
''')
        self.executable("fzf", '''#!/usr/bin/env python3
import os, sys
from pathlib import Path
rows = sys.stdin.read()
Path(os.environ["TEST_DIR"], "rows").write_text(rows)
for row in rows.splitlines():
    if row.split("\x1f")[1] == os.environ.get("PICK"):
        print(row)
        sys.exit(0)
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

    def run_script(self, script, name="", cwd=None, **env):
        return subprocess.run(["bash", str(PLUGIN / script)], input=name + "\n",
                              cwd=cwd or self.repo, env=dict(self.env, **env),
                              text=True, capture_output=True, timeout=10)

    def worktree(self, name):
        return Path(f"{self.repo}-worktrees") / name

    def assert_unchanged(self):
        self.assertEqual(self.git("branch", "--format=%(refname:short)"), "main")
        self.assertEqual(self.git("worktree", "list", "--porcelain").count("worktree "), 1)
        self.assertFalse(Path(f"{self.repo}-worktrees").exists())
        self.assertEqual(self.tmux("list-sessions", "-F", "#{session_name}"), "origin")

    def test_create_from_subdirectory_and_current_head(self):
        nested = self.repo / "nested"
        nested.mkdir()
        (nested / "dirty").write_text("uncommitted")
        self.git("checkout", "-qb", "source")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                 "commit", "-qm", "source commit", "--allow-empty")
        result = self.run_script("agents-new.sh", "task-1", cwd=nested)
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
        result = self.run_script("agents-new.sh", "task", cwd=linked)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.worktree("task") / ".git").is_file())

    def test_invalid_names_and_cancel_do_not_mutate(self):
        for name in ("", "bad name", "../escape", "topic/task", "-option", "a.b", "a:b", "$(touch bad)", "HEAD"):
            with self.subTest(name=name):
                result = self.run_script("agents-new.sh", name)
                self.assertEqual(result.returncode == 0, name == "", result.stderr)
                self.assert_unchanged()

    def test_non_repository_does_not_mutate(self):
        result = self.run_script("agents-new.sh", "task", cwd=self.root)
        self.assertNotEqual(result.returncode, 0)
        self.assert_unchanged()

    def test_existing_branch_is_not_reused(self):
        self.git("branch", "task")
        result = self.run_script("agents-new.sh", "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.worktree("task").exists())
        self.assertFalse((self.root / "pi.json").exists())
        self.assertIn("branch already exists", result.stderr)

    def test_existing_directory_is_not_overwritten(self):
        self.worktree("task").mkdir(parents=True)
        marker = self.worktree("task") / "keep"
        marker.write_text("keep")
        result = self.run_script("agents-new.sh", "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(marker.read_text(), "keep")
        self.assertEqual(self.git("branch", "--format=%(refname:short)"), "main")

    def test_dangling_symlink_is_not_overwritten(self):
        self.worktree("task").parent.mkdir()
        self.worktree("task").symlink_to(self.root / "missing")
        result = self.run_script("agents-new.sh", "task")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(self.worktree("task").is_symlink())
        self.assertEqual(self.git("branch", "--format=%(refname:short)"), "main")

    def test_tmux_name_prefix_is_not_a_collision(self):
        self.tmux("new-session", "-d", "-s", "task-long", "sleep", "600")
        result = self.run_script("agents-new.sh", "task")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.worktree("task").exists())

    def test_existing_tmux_session_is_not_reused(self):
        result = self.run_script("agents-new.sh", "origin")
        self.assertNotEqual(result.returncode, 0)
        self.assert_unchanged()

    def test_tmux_creation_failure_rolls_back_worktree_and_branch(self):
        result = self.run_script("agents-new.sh", "task", FAIL_NEW="1")
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
        result = self.run_script("agents-list.sh", PICK=pi_pane)
        self.assertEqual(result.returncode, 0, result.stderr)
        rows = (self.root / "rows").read_text().splitlines()
        self.assertEqual([r.split(SEP)[1] for r in rows], [pi_pane, "new"])
        self.assertIn("my task", rows[0])
        self.assertTrue((self.root / "switch.json").exists())
        self.assertEqual(self.tmux("display-message", "-p", "#{pane_id}"), pi_pane)

    def test_empty_list_can_create(self):
        result = self.run_script("agents-list.sh", "task", PICK="new")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.worktree("task").exists())

    def test_cancel_list_does_not_mutate(self):
        result = self.run_script("agents-list.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_unchanged()

    def test_binding_opens_in_current_directory_without_empty_guard(self):
        result = self.run_script("agents.tmux")
        self.assertEqual(result.returncode, 0, result.stderr)
        binding = next(line for line in self.tmux("list-keys", "-T", "prefix").splitlines()
                       if line.split()[3] == "a")
        self.assertIn("display-popup", binding)
        self.assertIn('-d "#{pane_current_path}"', binding)
        self.assertNotIn("if-shell", binding)

    def test_status_icons_match_list(self):
        self.tmux("set-option", "-g", "window-status-format", "#{agents}")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_name", "pi")
        self.run_script("agents.tmux")
        for state, icon in (("wait", "▲"), ("busy", "●"), ("done", "✓"), ("", "○")):
            with self.subTest(state=state):
                self.tmux("set-option", "-p", "-t", "%0", "@agent_state", state)
                result = self.run_script("agents-list.sh")
                self.assertEqual(result.returncode, 0, result.stderr)
                rows = (self.root / "rows").read_text().splitlines()
                self.assertIn(icon, rows[0])
                self.assertNotIn(f"({icon})", rows[0])
                self.assertIn("+ New pi session", rows[-1])
                status = self.tmux("display-message", "-p", "#{E:window-status-format}tab")
                if state:
                    self.assertNotIn(f"({icon})", status)
                    self.assertTrue(status.endswith(f"{icon}#[default]  tab"))
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
        self.run_script("agents.tmux")
        for option in options:
            with self.subTest(option=option):
                status = self.tmux("display-message", "-p", f"#{{E:{option}}}")
                self.assertIn("●#[default]  0:pi", status)
                self.assertNotIn("(●)", status)

    def test_status_ignores_non_pi_state(self):
        self.tmux("set-option", "-g", "window-status-format", "#{agents}")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_state", "wait")
        self.run_script("agents.tmux")
        self.assertEqual(self.tmux("display-message", "-p", "#{E:window-status-format}"), "")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_name", "pi")
        self.assertIn("▲", self.tmux("display-message", "-p", "#{E:window-status-format}"))

    def test_current_status_skips_active_pi_pane(self):
        self.tmux("set-option", "-g", "window-status-current-format", "#{agents}")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_name", "pi")
        self.tmux("set-option", "-p", "-t", "%0", "@agent_state", "wait")
        self.run_script("agents.tmux")
        self.assertEqual(self.tmux("display-message", "-p", "#{E:window-status-current-format}"), "")
        self.tmux("split-window", "-h", "sleep", "600")
        self.assertIn("▲", self.tmux("display-message", "-p", "#{E:window-status-current-format}"))


if __name__ == "__main__":
    unittest.main()
