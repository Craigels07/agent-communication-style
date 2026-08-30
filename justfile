set dotenv-load := true

# List available Claude Code launch modes.
default:
    @just --list

# Run the /install slash command in Claude Code — verifies just, claude, herdr, jq, pi.
install:
    claude --dangerously-skip-permissions "/install"

# Start Claude Code with Clear, Concise, Actionable Communication appended.
tuned-opus:
    claude --dangerously-skip-permissions --model "opus" --append-system-prompt-file "{{justfile_directory()}}/communication_style.md"

# Start the same Claude Code model without the custom communication instructions (the control).
stock-opus:
    claude --dangerously-skip-permissions --model "opus"

# Boot raw vs system-prompt-appended Opus 5 side by side in a herdr workspace and run the comparison prompt in both.
compare name:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # setup prompt
    DIR="{{justfile_directory()}}"
    PROMPT="explain zucks ai manifesto: $DIR/ai_docs/zuck-thefutureisforeveryone.md"
    
    # clear previous herdr
    herdr workspace list | jq -r '.result.workspaces[] | select(.label == "compare-{{name}}") | .workspace_id' | while read -r OLD; do herdr workspace close "$OLD"; done
    
    # open two herdr panes
    read -r WS ROOT < <(herdr workspace create --cwd "$DIR" --label "compare-{{name}}" --no-focus | jq -r '.result | "\(.workspace.workspace_id) \(.root_pane.pane_id)"')
    RIGHT=$(herdr pane split "$ROOT" --direction right --cwd "$DIR" --no-focus | jq -r '.result.pane.pane_id')
    
    # rename
    herdr pane rename "$ROOT" stock-opus-5
    herdr pane rename "$RIGHT" tuned-opus-5
    
    # prompt
    herdr pane run "$ROOT" "claude --dangerously-skip-permissions --model 'opus' '$PROMPT'"
    herdr pane run "$RIGHT" "claude --dangerously-skip-permissions --model 'opus' --append-system-prompt-file '$DIR/communication_style.md' '$PROMPT'"
    
    # coms
    echo "workspace $WS ready: left $ROOT (stock-opus-5, raw) | right $RIGHT (tuned-opus-5, system prompt appended)"

# ------------------------------------------------------------------
# Pi coding agent — mirrors the Claude Code recipes above
# ------------------------------------------------------------------

# Start Pi with Clear, Concise, Actionable Communication appended.
tuned-pi:
    pi --model "anthropic/claude-opus-5" --append-system-prompt "{{justfile_directory()}}/communication_style.md"

# Start the same Pi model without the custom communication instructions (the control).
stock-pi:
    pi --model "anthropic/claude-opus-5"

# Boot raw vs system-prompt-appended Opus 5 in Pi side by side in a herdr workspace and run the comparison prompt in both.
pi-compare name:
    #!/usr/bin/env bash
    set -euo pipefail

    # setup prompt
    DIR="{{justfile_directory()}}"
    PROMPT="explain zucks ai manifesto: $DIR/ai_docs/zuck-thefutureisforeveryone.md"

    # clear previous herdr
    herdr workspace list | jq -r '.result.workspaces[] | select(.label == "pi-compare-{{name}}") | .workspace_id' | while read -r OLD; do herdr workspace close "$OLD"; done

    # open two herdr panes
    read -r WS ROOT < <(herdr workspace create --cwd "$DIR" --label "pi-compare-{{name}}" --no-focus | jq -r '.result | "\(.workspace.workspace_id) \(.root_pane.pane_id)"')
    RIGHT=$(herdr pane split "$ROOT" --direction right --cwd "$DIR" --no-focus | jq -r '.result.pane.pane_id')

    # rename
    herdr pane rename "$ROOT" stock-pi-opus-5
    herdr pane rename "$RIGHT" tuned-pi-opus-5

    # prompt
    herdr pane run "$ROOT" "pi --model 'anthropic/claude-opus-5' '$PROMPT'"
    herdr pane run "$RIGHT" "pi --model 'anthropic/claude-opus-5' --append-system-prompt '$DIR/communication_style.md' '$PROMPT'"

    # coms
    echo "workspace $WS ready: left $ROOT (stock-pi-opus-5, raw) | right $RIGHT (tuned-pi-opus-5, system prompt appended)"
