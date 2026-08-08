/**
 * Publishes coding agent state to the tmux pane pi runs in. The @agent_state
 * pane option is the contract shared with tmux/plugins/agent-watch/agent-watch.tmux.
 *
 * Not an extension: this directory holds helpers, so pi's discovery of
 * extensions/*.ts and extensions/*!/index.ts skips it. No-op outside tmux.
 */

import { execFile } from "node:child_process";

export type AgentState = "busy" | "done" | "wait";

const pane = process.env.TMUX ? process.env.TMUX_PANE : undefined;

export const inTmux = Boolean(pane);

/** Publish a state, or clear the pane's state when called with nothing. */
export function publish(state?: AgentState) {
	if (!pane) return;

	const args = state
		? ["set-option", "-p", "-t", pane, "@agent_state", state]
		: ["set-option", "-pu", "-t", pane, "@agent_state"];

	// Redraw now instead of waiting for the next status-interval tick.
	execFile("tmux", args, () => execFile("tmux", ["refresh-client", "-S"], () => {}));
}
