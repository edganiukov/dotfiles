/**
 * FZF File Search - `/fzf:file` or Ctrl+F
 * Opens a fuzzy file finder, inserts selected file as @path
 */

import { spawn } from "node:child_process";
import type { ExtensionAPI, ExtensionContext, Theme } from "@mariozechner/pi-coding-agent";
import { Key, matchesKey, type TUI } from "@mariozechner/pi-tui";

const EXCLUDED = [
	"*/node_modules/*", "*/.git/*",
];

function loadFiles(cwd: string): Promise<string[]> {
	return new Promise((resolve) => {
		const args = ["--files", ...EXCLUDED.flatMap((p) => ["--ignore-file", p])];
		const proc = spawn("rg", args, { cwd });
		let output = "";

		proc.stdout.on("data", (d) => (output += d));
		proc.on("close", () => {
			const files = output.split("\n").filter(Boolean).map((f) => f.replace(/^\.\//, "")).sort();
			resolve(files);
		});
		proc.on("error", () => resolve([]));
	});
}

function fuzzyMatch(query: string, target: string): number | null {
	const q = query.toLowerCase(), t = target.toLowerCase();
	if (!q) return 0;

	let qi = 0, score = 0, prev = -1;
	for (let ti = 0; ti < t.length && qi < q.length; ti++) {
		if (t[ti] === q[qi]) {
			score += prev === ti - 1 ? 10 : 0;
			score += ti === 0 || "/._-".includes(t[ti - 1]) ? 5 : 0;
			prev = ti;
			qi++;
		}
	}
	return qi === q.length ? score : null;
}

function filter(files: string[], query: string): string[] {
	if (!query) return files.slice(0, 100);
	return files
		.map((f) => ({ f, s: fuzzyMatch(query, f) }))
		.filter((x) => x.s !== null)
		.sort((a, b) => b.s! - a.s! || a.f.localeCompare(b.f))
		.slice(0, 100)
		.map((x) => x.f);
}

class Finder {
	private files: string[] = [];
	private results: string[] = [];
	private index = 0;
	private query = "";
	private loading = true;
	private theme: Theme;
	private tui: TUI;

	onSelect?: (file: string) => void;
	onCancel?: () => void;

	constructor(tui: TUI, theme: Theme) {
		this.tui = tui;
		this.theme = theme;
	}

	setFiles(files: string[]) {
		this.files = files;
		this.results = filter(files, this.query);
		this.loading = false;
		this.tui.requestRender();
	}

	private updateQuery(q: string) {
		this.query = q;
		this.results = filter(this.files, q);
		this.index = 0;
		this.tui.requestRender();
	}

	handleInput(data: string) {
		if (matchesKey(data, Key.up) || matchesKey(data, Key.ctrl("p"))) {
			if (this.index > 0) { this.index--; this.tui.requestRender(); }
		} else if (matchesKey(data, Key.down) || matchesKey(data, Key.ctrl("n"))) {
			if (this.index < this.results.length - 1) { this.index++; this.tui.requestRender(); }
		} else if (matchesKey(data, Key.enter)) {
			if (this.results[this.index]) this.onSelect?.(this.results[this.index]);
		} else if (matchesKey(data, Key.escape)) {
			this.onCancel?.();
		} else if (matchesKey(data, Key.backspace)) {
			if (this.query) this.updateQuery(this.query.slice(0, -1));
		} else if (matchesKey(data, Key.ctrl("u"))) {
			this.updateQuery("");
		} else if (data.length === 1 && data >= " " && data < "\x7f") {
			this.updateQuery(this.query + data);
		}
	}

	render(width: number): string[] {
		const { theme, loading, query, results, index, files } = this;
		const inner = width - 4;
		const border = (s: string) => theme.fg("border", s);
		const line = (content: string) => {
			const len = content.replace(/\x1b\[[0-9;]*m/g, "").length;
			return border("│ ") + content + " ".repeat(Math.max(0, inner - len)) + border(" │");
		};

		const lines = [border("┌" + "─".repeat(width - 2) + "┐")];
		lines.push(line(theme.fg("text", `> ${query}█`)));

		const status = loading ? "Loading..." : query ? `${results.length}/${files.length}` : `${files.length} files`;
		lines.push(line(theme.fg("muted", status)));
		lines.push(border("├" + "─".repeat(width - 2) + "┤"));

		const visible = 12;
		const start = Math.max(0, index - Math.floor(visible / 2));
		const end = Math.min(results.length, start + visible);

		for (let i = start; i < end; i++) {
			const sel = i === index;
			const text = (sel ? "> " : "  ") + results[i];
			lines.push(line(sel ? theme.fg("accent", text) : theme.fg("text", text)));
		}
		for (let i = end - start; i < visible; i++) lines.push(border("│") + " ".repeat(width - 2) + border("│"));

		if (results.length > visible) {
			lines.push(line(theme.fg("dim", `[${index + 1}/${results.length}]`)));
		} else {
			lines.push(border("│") + " ".repeat(width - 2) + border("│"));
		}

		lines.push(border("└" + "─".repeat(width - 2) + "┘"));
		return lines;
	}

	invalidate() {}
}

export default function (pi: ExtensionAPI) {
	async function openFinder(ctx: ExtensionContext) {
		if (!ctx.hasUI) return;

		const result = await ctx.ui.custom<string | null>(
			(tui, theme, _kb, done) => {
				const finder = new Finder(tui, theme);
				finder.onSelect = done;
				finder.onCancel = () => done(null);
				loadFiles(ctx.cwd).then((f) => f.length ? finder.setFiles(f) : done(null));
				return finder;
			},
			{ overlay: true, overlayOptions: { anchor: "center", width: "60%", minWidth: 40, maxWidth: 100 } },
		);

		if (result) {
			const text = ctx.ui.getEditorText();
			ctx.ui.setEditorText(text ? `${text} @${result}` : `@${result}`);
			ctx.ui.setStatus("_", "");
			ctx.ui.setStatus("_", undefined);
		}
	}

	// pi.registerShortcut("ctrl+f", {
	// 	description: "Fuzzy file finder",
	// 	handler: openFinder,
	// });

	pi.registerCommand("fzf:file", {
		description: "Fuzzy file finder",
		handler: (_args, ctx) => openFinder(ctx),
	});
}
