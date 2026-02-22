#!/usr/bin/env bash
# UserPromptSubmit hook: catch-all for any remaining queued ideas
# Safety net — picks up anything PostToolUse and Stop didn't catch

QUEUE_FILE="$HOME/.claude/andthen-queue.jsonl"

# Fast bail
[ ! -s "$QUEUE_FILE" ] && exit 0

# Acquire lock and drain queue
LOCK_DIR="$HOME/.claude/andthen-lock"
TEMP_FILE="$HOME/.claude/andthen-drain-prompt-$$.jsonl"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  # Lock held, skip — ideas will be caught elsewhere
  exit 0
fi
trap 'rm -rf "$LOCK_DIR"' EXIT

if ! mv "$QUEUE_FILE" "$TEMP_FILE" 2>/dev/null; then
  exit 0
fi

# Parse ideas
IDEAS=""
while IFS= read -r line; do
  idea=$(echo "$line" | jq -r '.idea // empty' 2>/dev/null)
  if [ -n "$idea" ]; then
    if [ -n "$IDEAS" ]; then
      IDEAS="$IDEAS"$'\n'"- $idea"
    else
      IDEAS="- $idea"
    fi
  fi
done < "$TEMP_FILE"

rm -f "$TEMP_FILE"

[ -z "$IDEAS" ] && exit 0

CONTEXT="The user queued up some ideas between turns — treat them as part of the current conversation:

$IDEAS

Integrate naturally. No need to make a big deal of it — just acknowledge and go."

CONTEXT_JSON=$(printf '%s' "$CONTEXT" | jq -Rs .)

cat <<EOF
{"additionalContext": $CONTEXT_JSON}
EOF
