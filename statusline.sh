#!/usr/bin/env bash
exec jq -r '
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
  "tok: \($cw.total_input_tokens | fmt_tok) in / \($cw.total_output_tokens | fmt_tok) out (\($cw.used_percentage // 0)% ctx) | time: \($c.total_api_duration_ms | fmt_sec) api / \($c.total_duration_ms | fmt_sec) wall | $\(($c.total_cost_usd // 0) * 100 | round / 100)"
'
