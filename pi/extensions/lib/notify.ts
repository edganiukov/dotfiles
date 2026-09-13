/**
 * Desktop notification, for when pi needs you and tmux is not in front of you.
 * Linux uses notify-send (dunst here); macOS uses osascript. Best-effort: a
 * missing tool or a failed call is silently ignored, never surfaced to pi.
 */

import { execFile } from "node:child_process";

export function notify(title: string, body: string) {
	if (process.platform === "darwin") {
		// osascript takes a script, not argv, so the strings go in as escaped
		// AppleScript literals rather than being spliced into the source.
		const quote = (s: string) => `"${s.replace(/[\\"]/g, "\\$&")}"`;
		execFile(
			"osascript",
			["-e", `display notification ${quote(body)} with title ${quote(title)}`],
			() => {},
		);
		return;
	}

	execFile("notify-send", ["--app-name=pi", "--urgency=normal", title, body], () => {});
}
