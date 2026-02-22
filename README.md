# andthen

Queue ideas for Claude Code without interrupting. Built for fast brains.

## The problem

You're working with Claude Code. It's mid-turn, editing files, running tests. Your brain fires off a great idea — "oh, also add rate limiting!" But there's no way to tell Claude without hitting Ctrl+C and killing its current work.

**andthen** fixes this. Fire-and-forget idea queuing that hooks directly into Claude's processing loop.

## How it works

```
Terminal 1 (Claude working)          Terminal 2 (your fast brain)
─────────────────────────────        ─────────────────────────────
> Fix the auth bug
[Claude reading files...]            $ at "also add rate limiting"
[Claude editing code...]             + Queued: also add rate limiting
[Hook injects idea ↓]
"Love it — adding rate limiting"     $ at "oh and dark mode too"
[Claude continues working...]        + Queued: oh and dark mode too
```

Three hooks catch your ideas at different points:
- **PostToolUse** — between every tool call (~seconds). The instant path.
- **Stop** — when Claude finishes its turn. Blocks stop, feeds ideas, Claude continues.
- **UserPromptSubmit** — when you type your next prompt. Belt-and-suspenders catch-all.

## Install

```bash
# Clone or download
cd andthen

# Run installer (creates `andthen` and `at` symlinks)
bash bin/install.sh

# Use with Claude Code
claude --plugin-dir ./
```

## Usage

```bash
# Queue an idea (2 characters!)
at "add rate limiting"

# Queue another
at "oh and dark mode too"

# View the queue
andthen --list
andthen -l

# Clear the queue
andthen --clear
andthen -c

# Count queued ideas
andthen --count
andthen -n

# Interactive mode (one idea per line, Ctrl+D to finish)
andthen

# Pipe ideas
echo "add tests" | andthen
```

## Inside Claude Code

Use the `/andthen` slash command to view and manage the queue from within a Claude session.

## How Claude responds

When your ideas arrive, Claude acknowledges with warm, positive energy:

- "Love it — adding rate limiting too"
- "Great call, I'll add dark mode"
- "On it — tests are a great idea"
- "Nice one, weaving that in"

One line, then back to work. No "hold on", no "that's a lot", no friction. Your ideas are always welcome.

## Design

| Choice | Why |
|--------|-----|
| JSONL queue | Append-only, atomic on POSIX, no corruption from concurrent writes |
| `mkdir`-based locking | Atomic on all POSIX systems, works on macOS (no `flock` needed) |
| Fast empty-queue bail | `[ ! -s file ]` is a single stat() call, <1ms on every tool call |
| 3 hook points | Speed (PostToolUse) + completeness (Stop) + safety net (UserPromptSubmit) |
| Stop throttle (2/60s) | Prevents infinite loops if ideas arrive faster than Claude processes |
| `at` alias | 2 chars. Worth shadowing the rarely-used POSIX `at` scheduler |

## Requirements

- Claude Code with plugin support
- `jq` (for JSON handling in hooks)
- Bash 3.2+ (macOS default works fine)

## Philosophy

Your fast brain is a feature, not a bug. Every idea you queue is you trusting Claude with your stream of consciousness. andthen makes sure that trust is honored — no interruptions, no lost ideas, no guilt.
