#!/usr/bin/env bash
# Install andthen CLI tool and create symlinks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLI_PATH="$SCRIPT_DIR/andthen"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[0;2m'
RESET='\033[0m'

echo -e "${BOLD}Installing andthen...${RESET}"
echo ""

# Make CLI executable
chmod +x "$CLI_PATH"

# Make hooks executable
HOOKS_DIR="$(dirname "$SCRIPT_DIR")/hooks"
if [ -d "$HOOKS_DIR" ]; then
  chmod +x "$HOOKS_DIR"/*.sh 2>/dev/null || true
fi

# Find a suitable bin directory in PATH
BIN_DIR=""
for dir in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
  if echo "$PATH" | tr ':' '\n' | grep -qx "$dir"; then
    BIN_DIR="$dir"
    break
  fi
done

if [ -z "$BIN_DIR" ]; then
  # Default to ~/.local/bin and suggest adding to PATH
  BIN_DIR="$HOME/.local/bin"
  echo -e "${YELLOW}Note:${RESET} $BIN_DIR is not in your PATH"
  echo -e "  Add this to your shell profile:"
  echo -e "  ${DIM}export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}"
  echo ""
fi

mkdir -p "$BIN_DIR"

# Create symlinks
create_link() {
  local name="$1"
  local target="$BIN_DIR/$name"

  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ]; then
    echo -e "${YELLOW}!${RESET} $target already exists (not a symlink), skipping"
    return
  fi

  ln -s "$CLI_PATH" "$target"
  echo -e "${GREEN}+${RESET} Linked: ${CYAN}$name${RESET} -> $CLI_PATH"
}

create_link "andthen"

# Check if `at` would shadow the POSIX at command
if command -v at >/dev/null 2>&1; then
  AT_PATH=$(command -v at)
  if [ "$AT_PATH" != "$BIN_DIR/at" ]; then
    echo -e ""
    echo -e "${YELLOW}Note:${RESET} Creating ${CYAN}at${RESET} symlink will shadow ${DIM}$AT_PATH${RESET} (POSIX job scheduler)"
    echo -e "  This is usually fine — the POSIX ${DIM}at${RESET} command is rarely used."
    echo -e "  The original is still available at ${DIM}$AT_PATH${RESET}"
  fi
fi

create_link "at"

echo ""
echo -e "${GREEN}Done!${RESET} Try it out:"
echo -e "  ${CYAN}at \"add dark mode\"${RESET}"
echo -e "  ${CYAN}andthen --list${RESET}"

# Ensure queue directory exists
mkdir -p "$HOME/.claude"
