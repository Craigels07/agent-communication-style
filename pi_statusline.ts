// Pi footer that mirrors statusline.sh, so pi panes show the same stats as the
// Claude Code panes. Everything is cumulative for the session.
//
// Loaded with -e from PI_ISO. --no-extensions still loads explicit -e paths.

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const fmtTok = (n: number) =>
	n >= 1_000_000 ? `${Math.round(n / 100_000) / 10}M` : n >= 1000 ? `${Math.round(n / 100) / 10}k` : `${n}`;
const fmtSec = (ms: number) => `${Math.round(ms / 100) / 10}s`;

// style: the file passed to --append-system-prompt, or "default" for the stock pane.
const argv = process.argv;
const styleArg = argv[argv.indexOf("--append-system-prompt") + 1];
const style = argv.includes("--append-system-prompt") && styleArg
	? styleArg.split("/").pop()!.replace(/\.md$/, "")
	: "default";

export default function (pi: ExtensionAPI) {
	const started = Date.now();
	let apiMs = 0;
	let requestStart: number | undefined;

	// api time: provider request sent until the assistant message finishes.
	pi.on("before_provider_request", () => {
		requestStart = Date.now();
	});
	pi.on("message_end", (event) => {
		if (event.message.role === "assistant" && requestStart !== undefined) {
			apiMs += Date.now() - requestStart;
			requestStart = undefined;
		}
	});

	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setFooter((tui, _theme, _footerData) => {
			// wall time keeps moving between events, so re-render once a second
			const timer = setInterval(() => tui.requestRender(), 1000);
			return {
				dispose: () => clearInterval(timer),
				invalidate() {},
				render(width: number): string[] {
					let input = 0;
					let output = 0;
					let cost = 0;
					let chars = 0;
					for (const e of ctx.sessionManager.getBranch()) {
						if (e.type !== "message" || e.message.role !== "assistant") continue;
						const m = e.message as AssistantMessage;
						// Claude Code's total_input_tokens counts cache reads and writes too
						input += m.usage.input + m.usage.cacheRead + m.usage.cacheWrite;
						output += m.usage.output;
						cost += m.usage.cost.total;
						for (const c of m.content) if (c.type === "text") chars += [...c.text].length;
					}
					const ctxPct = Math.round(ctx.getContextUsage()?.percent ?? 0);
					const model = ctx.model?.name ?? "no-model";

					// out tokens first: the leftmost field is the one that survives a narrow pane
					const line =
						`out: ${fmtTok(output)} | ${fmtTok(chars)} chars` +
						` | in: ${fmtTok(input)} (${ctxPct}% ctx)` +
						` | $${Math.round(cost * 100) / 100}` +
						` | ${fmtSec(apiMs)} api / ${fmtSec(Date.now() - started)} wall` +
						` | ${model} ${pi.getThinkingLevel()} · style: ${style}`;
					return [truncateToWidth(line, width)];
				},
			};
		});
	});
}
