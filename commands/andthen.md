---
name: andthen
description: View and manage the andthen idea queue
---

# /andthen — View Idea Queue

Check the andthen idea queue and report its contents to the user.

## Steps

1. Read the queue file at `~/.claude/andthen-queue.jsonl`
2. If the file doesn't exist or is empty, tell the user: "Queue is empty — no pending ideas."
3. If ideas exist, list them in a clean format:
   - Number each idea
   - Show the idea text
   - Show the timestamp
4. Ask if the user wants to clear the queue or keep the ideas for processing.

## Example output

```
Queued ideas:
1. Add rate limiting (queued 2 min ago)
2. Dark mode support (queued 30s ago)

Want me to work through these, or clear the queue?
```
