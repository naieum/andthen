#!/usr/bin/env bash
# Stop hook: block stop if ideas are queued
# Prevents Claude from finishing before processing queued ideas

QUEUE_FILE="$HOME/.claude/andthen-queue.jsonl"
THROTTLE_FILE="$HOME/.claude/andthen-stop-throttle"

# Read stdin to check for stop_hook_active (prevents infinite loops)
INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)

if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  # We're in a stop-hook-triggered continuation, don't block again
  exit 0
fi

# Fast bail: no ideas queued
[ ! -s "$QUEUE_FILE" ] && exit 0

# Throttle check: max 2 continuations per 60s window
NOW=$(date +%s)
THROTTLE_COUNT=0

if [ -f "$THROTTLE_FILE" ]; then
  # Count recent entries (within 60s)
  while IFS= read -r ts; do
    if [ -n "$ts" ] && [ "$((NOW - ts))" -lt 60 ]; then
      THROTTLE_COUNT=$((THROTTLE_COUNT + 1))
    fi
  done < "$THROTTLE_FILE"
fi

if [ "$THROTTLE_COUNT" -ge 2 ]; then
  # Throttle exceeded — let Claude stop, ideas will be caught on next prompt
  exit 0
fi

# Record this continuation
echo "$NOW" >> "$THROTTLE_FILE"

# Clean old entries from throttle file (keep last 60s only)
if [ -f "$THROTTLE_FILE" ]; then
  TEMP_THROTTLE="$THROTTLE_FILE.tmp"
  while IFS= read -r ts; do
    if [ -n "$ts" ] && [ "$((NOW - ts))" -lt 60 ]; then
      echo "$ts"
    fi
  done < "$THROTTLE_FILE" > "$TEMP_THROTTLE"
  mv "$TEMP_THROTTLE" "$THROTTLE_FILE"
fi

# Acquire lock and drain queue
LOCK_DIR="$HOME/.claude/andthen-lock"
TEMP_FILE="$HOME/.claude/andthen-drain-stop-$$.jsonl"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  # Lock held — another hook is draining, let stop proceed
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

REASON="Before you wrap up — the user had more ideas they queued while you were working:

$IDEAS

Please address these before finishing. Acknowledge warmly and keep going!"

REASON_JSON=$(printf '%s' "$REASON" | jq -Rs .)

cat <<EOF
{"decision":"block","reason":$REASON_JSON}
EOF
