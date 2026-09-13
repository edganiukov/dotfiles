/**
 * Publishes coding agent state to the tmux pane pi runs in. The @agent_state
 * pane option is the contract shared with tmux/plugins/pimux/pimux.tmux.
 *
 * Not an extension: this directory holds helpers, so pi's discovery of
 * extensions/*.ts and extensions/*!/index.ts skips it. No-op outside tmux.
 */

import { execFile } from "node:child_process";

export type AgentState = "busy" | "done" | "wait";

const pane = process.env.TMUX ? process.env.TMUX_PANE : undefined;

export const inTmux = Boolean(pane);

/**
 * Publish a state, or clear the pane's state when called with nothing.
 *
 * Also stamps @agent_since with when the state changed, so the list can show
 * how long an agent has been done or blocked. tmux's own window_activity is
 * no use for that: it ticks on any output, including pi's own spinner.
 */
export function publish(state?: AgentState) {
	if (!pane) return;

	const since = String(Math.floor(Date.now() / 1000));
	const args = state
		? ["set-option", "-p", "-t", pane, "@agent_state", state, ";",
			"set-option", "-p", "-t", pane, "@agent_since", since]
		: ["set-option", "-pu", "-t", pane, "@agent_state", ";",
			"set-option", "-pu", "-t", pane, "@agent_since"];

	// Redraw now instead of waiting for the next status-interval tick.
	execFile("tmux", args, () => execFile("tmux", ["refresh-client", "-S"], () => {}));
}

/** Name this pane's window after the agent, or hand naming back to tmux. */
export function publishName(name?: string) {
	if (!pane) return;

	const args = name
		? ["set-option", "-p", "-t", pane, "@agent_name", name]
		: ["set-option", "-pu", "-t", pane, "@agent_name"];

	execFile("tmux", args, () => {});
}

/** Label this pane's agent session for the agent list, or clear it. */
export function publishSession(label?: string) {
	if (!pane) return;

	const args = label
		? ["set-option", "-p", "-t", pane, "@agent_session", label]
		: ["set-option", "-pu", "-t", pane, "@agent_session"];

	execFile("tmux", args, () => {});
}
