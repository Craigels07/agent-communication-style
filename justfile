set dotenv-load := true

# Isolation: both arms run with no CLAUDE.md, no output style, no plugins, no skills,
# no hooks, no user/project settings. The only difference between panes is the
# appended system prompt. Effort and thinking are pinned so the arms match.
# Not --safe-mode: it also disables the status line, so token counts vanish.
CLAUDE_ISO := "--setting-sources '' --effort high"
PI_ISO := "--no-context-files --no-skills --no-extensions --thinking high"

# List available launch modes.
default:
    @just --list

# Check claude, pi, herdr, jq are installed.
install:
    claude --dangerously-skip-permissions "/install"

# Opus 5 + one system prompt from system_prompts/ (caveman_style | communication_style | eli5_style).
tuned-opus style="communication_style":
    claude --settings '{"statusLine":{"type":"command","command":"{{justfile_directory()}}/statusline.sh"}}' --dangerously-skip-permissions --model "opus" {{CLAUDE_ISO}} --append-system-prompt-file "{{justfile_directory()}}/system_prompts/{{style}}.md"

# Opus 5 with no system prompt (the control).
stock-opus:
    claude --settings '{"statusLine":{"type":"command","command":"{{justfile_directory()}}/statusline.sh"}}' --dangerously-skip-permissions --model "opus" {{CLAUDE_ISO}}

# Opus 5 stock + every system prompt, side by side in herdr. <name> labels the workspace.
compare name="demo":
    #!/usr/bin/env bash
    set -euo pipefail

    # setup prompt
    DIR="{{justfile_directory()}}"
    PROMPT="explain the brooks no silver bullet paper: $DIR/ai_docs/brooks-no-silver-bullet.md"
    SETTINGS="{\"statusLine\":{\"type\":\"command\",\"command\":\"$DIR/statusline.sh\"}}"
    CLAUDE="claude --settings '$SETTINGS' --dangerously-skip-permissions --model 'opus' {{CLAUDE_ISO}}"

    # clear previous herdr
    herdr workspace list | jq -r '.result.workspaces[] | select(.label == "compare-{{name}}") | .workspace_id' | while read -r OLD; do herdr workspace close "$OLD"; done

    # one pane for stock, then one per prompt in system_prompts/
    # --ratio gives that fraction to the pane being split, so 1/remaining leaves every pane equal
    STYLES=("$DIR"/system_prompts/*.md)
    LEFT=$(( ${#STYLES[@]} + 1 ))

    read -r WS PANE < <(herdr workspace create --cwd "$DIR" --label "compare-{{name}}" | jq -r '.result | "\(.workspace.workspace_id) \(.root_pane.pane_id)"')
    herdr pane rename "$PANE" stock
    herdr pane run "$PANE" "$CLAUDE '$PROMPT'"
    echo "workspace $WS: $PANE (stock, raw)"

    for STYLE in "${STYLES[@]}"; do
        NAME=$(basename "$STYLE" .md)
        RATIO=$(awk "BEGIN{printf \"%.4f\", 1/$LEFT}")
        PANE=$(herdr pane split "$PANE" --direction right --ratio "$RATIO" --cwd "$DIR" --no-focus | jq -r '.result.pane.pane_id')
        LEFT=$(( LEFT - 1 ))
        herdr pane rename "$PANE" "$NAME"
        herdr pane run "$PANE" "$CLAUDE --append-system-prompt-file '$STYLE' '$PROMPT'"
        echo "workspace $WS: $PANE ($NAME)"
    done

# ------------------------------------------------------------------
# Demo rounds
# ------------------------------------------------------------------

# Demo round 1: stock vs communication_style, two panes. <name> labels the workspace.
demo-round1 name="round1":
    #!/usr/bin/env bash
    set -euo pipefail

    DIR="{{justfile_directory()}}"
    PROMPT="explain the brooks no silver bullet paper: $DIR/ai_docs/brooks-no-silver-bullet.md"
    SETTINGS="{\"statusLine\":{\"type\":\"command\",\"command\":\"$DIR/statusline.sh\"}}"
    CLAUDE="claude --settings '$SETTINGS' --dangerously-skip-permissions --model 'opus' {{CLAUDE_ISO}}"

    herdr workspace list | jq -r '.result.workspaces[] | select(.label == "demo-{{name}}") | .workspace_id' | while read -r OLD; do herdr workspace close "$OLD"; done

    read -r WS PANE < <(herdr workspace create --cwd "$DIR" --label "demo-{{name}}" | jq -r '.result | "\(.workspace.workspace_id) \(.root_pane.pane_id)"')
    herdr pane rename "$PANE" stock
    herdr pane run "$PANE" "$CLAUDE '$PROMPT'"
    echo "workspace $WS: $PANE (stock)"

    PANE=$(herdr pane split "$PANE" --direction right --ratio 0.5 --cwd "$DIR" --no-focus | jq -r '.result.pane.pane_id')
    herdr pane rename "$PANE" communication_style
    herdr pane run "$PANE" "$CLAUDE --append-system-prompt-file '$DIR/system_prompts/communication_style.md' '$PROMPT'"
    echo "workspace $WS: $PANE (communication_style)"

# Demo round 2: stock + every system prompt in system_prompts/. <name> labels the workspace.
demo-round2 name="round2":
    @just compare "{{name}}"

# ------------------------------------------------------------------
# Pi coding agent — mirrors the Claude Code recipes above
# ------------------------------------------------------------------

# Pi + one system prompt from system_prompts/ (caveman_style | communication_style | eli5_style).
tuned-pi style="communication_style":
    pi --model "anthropic/claude-opus-5" {{PI_ISO}} --append-system-prompt "{{justfile_directory()}}/system_prompts/{{style}}.md"

# Pi with no system prompt (the control).
stock-pi:
    pi --model "anthropic/claude-opus-5" {{PI_ISO}}

# Pi stock + every system prompt, side by side in herdr. <name> labels the workspace.
pi-compare name="demo":
    #!/usr/bin/env bash
    set -euo pipefail

    # setup prompt
    DIR="{{justfile_directory()}}"
    PROMPT="explain the brooks no silver bullet paper: $DIR/ai_docs/brooks-no-silver-bullet.md"
    PI="pi --model 'anthropic/claude-opus-5' {{PI_ISO}}"

    # clear previous herdr
    herdr workspace list | jq -r '.result.workspaces[] | select(.label == "pi-compare-{{name}}") | .workspace_id' | while read -r OLD; do herdr workspace close "$OLD"; done

    # one pane for stock, then one per prompt in system_prompts/
    # --ratio gives that fraction to the pane being split, so 1/remaining leaves every pane equal
    STYLES=("$DIR"/system_prompts/*.md)
    LEFT=$(( ${#STYLES[@]} + 1 ))

    read -r WS PANE < <(herdr workspace create --cwd "$DIR" --label "pi-compare-{{name}}" | jq -r '.result | "\(.workspace.workspace_id) \(.root_pane.pane_id)"')
    herdr pane rename "$PANE" stock
    herdr pane run "$PANE" "$PI '$PROMPT'"
    echo "workspace $WS: $PANE (stock, raw)"

    for STYLE in "${STYLES[@]}"; do
        NAME=$(basename "$STYLE" .md)
        RATIO=$(awk "BEGIN{printf \"%.4f\", 1/$LEFT}")
        PANE=$(herdr pane split "$PANE" --direction right --ratio "$RATIO" --cwd "$DIR" --no-focus | jq -r '.result.pane.pane_id')
        LEFT=$(( LEFT - 1 ))
        herdr pane rename "$PANE" "$NAME"
        herdr pane run "$PANE" "$PI --append-system-prompt '$STYLE' '$PROMPT'"
        echo "workspace $WS: $PANE ($NAME)"
    done
