/**
 * tmux Agent Watch Extension
 *
 * Publishes pi's state to the tmux pane it runs in so the tab gets flagged when
 * pi finishes a turn. Blocking prompts publish "wait" from wherever they are
 * raised; see permissions-gate.ts.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { inTmux, publish } from "./lib/tmux-agent-state.ts";

export default function (pi: ExtensionAPI) {
	if (!inTmux) return;

	pi.on("session_start", async () => publish());
	pi.on("session_shutdown", async () => publish());

	pi.on("agent_start", async (_event, ctx) => {
		if (ctx.mode === "tui") publish("busy");
	});

	// agent_settled, not agent_end: pi may still retry, compact, or run follow-ups.
	pi.on("agent_settled", async (_event, ctx) => {
		if (ctx.mode === "tui") publish("done");
	});
}
