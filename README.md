# andthen

Queue ideas for Claude Code without interrupting. Built for fast brains.

## The problem

You're working with Claude Code. It's mid-turn, editing files, running tests. Your brain fires off a great idea — "oh, also add rate limiting!" But there's no way to tell Claude without hitting Ctrl+C and killing its current work.

**andthen** fixes this. Type `/add` right inside Claude Code and your idea queues instantly.

## How it works

```
Claude is working                    You type
─────────────────────────────        ─────────────────────────
> Fix the auth bug
[Claude reading files...]            /add also add rate limiting
[Claude editing code...]             + Added: also add rate limiting
[Hook injects idea ↓]
"Love it — adding rate limiting"     /add oh and dark mode too
[Claude continues working...]        + Added: oh and dark mode too
```

Three hooks catch your ideas at different points:
- **PostToolUse** — between every tool call (~seconds). The instant path.
- **Stop** — when Claude finishes its turn. Blocks stop, feeds ideas, Claude continues.
- **UserPromptSubmit** — when you type your next prompt. Belt-and-suspenders catch-all.

## Install

**From inside Claude Code:**

```
/plugin marketplace add naieum/andthen
/plugin install andthen@andthen
```

That's it. `/add` is now available. Updates come through the marketplace too.

**Or manually:**

```bash
git clone https://github.com/naieum/andthen.git ~/.claude/plugins/andthen
claude --plugin-dir ~/.claude/plugins/andthen
```

**Want the CLI too?** For queuing ideas from a second terminal:

```bash
cd ~/.claude/plugins/andthen && bash bin/install.sh
```

Now `at "your idea"` works from any terminal.

## Usage

```bash
# Inside Claude Code — just type:
/add rate limiting
/add oh and dark mode too

# View the queue
/andthen

# From a second terminal (after install.sh)
at "add tests for the auth module"
andthen --list
andthen --clear
```

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
| `/add` command | Queue ideas without leaving Claude Code |
| `at` alias | 2 chars from a second terminal. Worth shadowing the rarely-used POSIX `at` scheduler |

## Requirements

- Claude Code with plugin support
- `jq` (for JSON handling in hooks)
- Bash 3.2+ (macOS default works fine)

## Philosophy

Your fast brain is a feature, not a bug. Every idea you queue is you trusting Claude with your stream of consciousness. andthen makes sure that trust is honored — no interruptions, no lost ideas, no guilt.
