#!/usr/bin/env bash
# Per-pane demo stats. Everything here is cumulative for the session, so the
# numbers keep climbing as you fire more prompts into the same pane.
#
# chars comes from the transcript, not the statusline payload: it is the raw
# size of every assistant text block, which is the thing the audience can see
# on screen. Tokens and cost come from the payload.

IN=$(cat)

CHARS=""
TRANSCRIPT=$(printf '%s' "$IN" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    # -j so jq adds no newlines of its own; wc -m then counts real characters.
    CHARS=$(jq -j 'select(.type=="assistant")
                   | .message.content[]?
                   | select(.type=="text")
                   | .text' "$TRANSCRIPT" 2>/dev/null | wc -m | tr -d ' ')
fi

printf '%s' "$IN" | exec jq -r --arg chars "$CHARS" '
  def fmt_tok:
    if . == null then "0"
    elif . >= 1000000 then "\(. / 1000000 | . * 10 | round / 10)M"
    elif . >= 1000 then "\(. / 1000 | . * 10 | round / 10)k"
    else "\(.)"
    end;
  def fmt_sec:
    if . == null then "0s"
    else "\(. / 1000 | . * 10 | round / 10)s"
    end;

  .context_window as $cw |
  .cost as $c |
  # out tokens first: that is the number the system prompt actually moves,
  # and the leftmost field is the one that survives a narrow pane.
  "out: \($cw.total_output_tokens | fmt_tok)" +
  (if $chars == "" then "" else " | \($chars | tonumber | fmt_tok) chars" end) +
  " | in: \($cw.total_input_tokens | fmt_tok) (\($cw.used_percentage // 0)% ctx)" +
  " | $\(($c.total_cost_usd // 0) * 100 | round / 100)" +
  " | \($c.total_api_duration_ms | fmt_sec) api / \($c.total_duration_ms | fmt_sec) wall" +
  # isolation check: style "default" and a matching effort level mean the pane
  # is running the model plus the appended file, nothing else.
  " | \(.model.display_name) \(.effort.level) · style: \(.output_style.name)"
'
