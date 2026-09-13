/**
 * tmux Extension
 *
 * Publishes pi's state to the tmux pane it runs in so the tab gets flagged when
 * pi finishes a turn, and labels the pane with this session's name so the agent
 * list can tell two pi sessions in the same project apart.
 *
 * It also names the window "pi": tmux takes the automatic name from the process
 * image, which for pi is node, and macOS ignores the process.title pi sets.
 *
 * Any blocking ctx.ui prompt, from any extension, flags the pane as waiting and
 * sends a desktop notification. pi fires ui_prompt_start/ui_prompt_end around
 * every select/confirm/input/editor/custom call and coalesces nested prompts,
 * so this covers permission gates, review pickers and the like in one place.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { notify } from "./lib/notify.ts";
import { type AgentState, inTmux, publish, publishName, publishSession } from "./lib/tmux-agent-state.ts";

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

	// What the pane showed before a prompt took over, so ending the prompt puts
	// it back rather than always claiming "busy": a /review picker opened from
	// an idle session should return to idle, not look like a running turn.
	let beforePrompt: AgentState | undefined;
	let current: AgentState | undefined;

	function setState(state?: AgentState) {
		current = state;
		publish(state);
	}

	pi.on("session_start", async (_event, ctx) => {
		setState();
		publishName("pi");
		publishSession(sessionLabel(ctx));
	});

	pi.on("session_info_changed", async (event, ctx) => {
		publishSession(event.name ?? sessionLabel(ctx));
	});

	pi.on("session_shutdown", async () => {
		setState();
		publishName();
		publishSession();
	});

	pi.on("agent_start", async (_event, ctx) => {
		if (ctx.mode === "tui") setState("busy");
	});

	// agent_settled, not agent_end: pi may still retry, compact, or run follow-ups.
	pi.on("agent_settled", async (_event, ctx) => {
		if (ctx.mode === "tui") setState("done");
	});

	pi.on("ui_prompt_start", async (event, ctx) => {
		if (ctx.mode !== "tui") return;
		beforePrompt = current;
		setState("wait");
		const label = sessionLabel(ctx) ?? "pi";
		notify(`${label} needs input`, event.title ?? `Waiting on a ${event.kind} prompt`);
	});

	pi.on("ui_prompt_end", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		setState(beforePrompt);
		beforePrompt = undefined;
	});
}
