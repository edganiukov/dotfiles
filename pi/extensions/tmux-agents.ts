/**
 * tmux Agent Watch Extension
 *
 * Publishes pi's state to the tmux pane it runs in so the tab gets flagged when
 * pi finishes a turn, and labels the pane with this session's name so the agent
 * list can tell two pi sessions in the same project apart.
 *
 * pi has no event for "blocked on a dialog", so prompts that block the agent
 * publish "wait" themselves; see permissions-gate.ts.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { inTmux, publish, publishSession } from "./lib/tmux-agent-state.ts";

// pi only names a session when asked to, so fall back to a short id to keep
// unnamed sessions distinguishable.
function sessionLabel(ctx: ExtensionContext): string | undefined {
	const name = ctx.sessionManager.getSessionName();
	if (name) return name;

	const id = ctx.sessionManager.getSessionId();
	return id ? id.slice(0, 8) : undefined;
}

export default function (pi: ExtensionAPI) {
	if (!inTmux) return;

	pi.on("session_start", async (_event, ctx) => {
		publish();
		publishSession(sessionLabel(ctx));
	});

	pi.on("session_info_changed", async (event, ctx) => {
		publishSession(event.name ?? sessionLabel(ctx));
	});

	pi.on("session_shutdown", async () => {
		publish();
		publishSession();
	});

	pi.on("agent_start", async (_event, ctx) => {
		if (ctx.mode === "tui") publish("busy");
	});

	// agent_settled, not agent_end: pi may still retry, compact, or run follow-ups.
	pi.on("agent_settled", async (_event, ctx) => {
		if (ctx.mode === "tui") publish("done");
	});
}
