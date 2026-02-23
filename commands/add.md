---
name: add
description: Queue an idea for later — don't lose the thought
---

# /add — Queue an idea

The user wants to queue an idea without derailing what you're doing.

## What to do

1. Extract the idea from everything after `/add` in the user's message
2. Write it to the queue file at `~/.claude/andthen-queue.jsonl` as a single JSONL line:
   ```
   {"idea": "the idea text", "timestamp": "ISO-8601 UTC"}
   ```
   Append to the file (create it if it doesn't exist).
3. Acknowledge in **one short line** — warm, positive, zero friction:
   - "+ Added: [idea]"
   - "Queued — [idea]"
   - "Got it — [idea]"
4. **Do not act on the idea right now.** Just queue it. The hooks will inject it at the right time.

## Example

User types: `/add also add rate limiting`

You do:
```bash
echo '{"idea":"also add rate limiting","timestamp":"2026-02-22T23:00:00Z"}' >> ~/.claude/andthen-queue.jsonl
```

Then respond: `+ Added: also add rate limiting`

That's it. One line. Back to whatever you were doing.
