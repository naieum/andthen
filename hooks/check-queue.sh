#!/usr/bin/env bash
# PostToolUse hook: inject queued ideas mid-turn
# Runs on EVERY tool call — must be <1ms when queue is empty

QUEUE_FILE="$HOME/.claude/andthen-queue.jsonl"

# Fast bail: single stat call, <1ms when nothing queued
[ ! -s "$QUEUE_FILE" ] && exit 0

# Ideas exist — acquire lock and atomically read+clear the queue
LOCK_DIR="$HOME/.claude/andthen-lock"
TEMP_FILE="$HOME/.claude/andthen-drain-$$.jsonl"

# mkdir is atomic on POSIX
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  # Another process has the lock, skip this cycle (we'll catch it next tool call)
  exit 0
fi

# Cleanup lock on exit
trap 'rm -rf "$LOCK_DIR"' EXIT

# Atomically move queue to temp file (read-and-clear in one op)
if ! mv "$QUEUE_FILE" "$TEMP_FILE" 2>/dev/null; then
  # Queue disappeared between check and move (race with another hook)
  exit 0
fi

# Parse ideas from JSONL
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

# Nothing valid parsed
[ -z "$IDEAS" ] && exit 0

# Output context for Claude
CONTEXT="The user had a great idea while you were working! They queued this up without wanting to interrupt you:

$IDEAS

Acknowledge warmly (one short line — \"Love it\", \"Great call\", \"On it\") and naturally integrate into your current work. Don't stop what you're doing."

# Escape for JSON
CONTEXT_JSON=$(printf '%s' "$CONTEXT" | jq -Rs .)

cat <<EOF
{"additionalContext": $CONTEXT_JSON}
EOF
