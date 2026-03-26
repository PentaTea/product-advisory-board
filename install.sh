#!/bin/bash
# Product Advisory Board — Install Script
# Installs both skill and agent definitions to the correct directories.

set -e

# Detect target: project-level (.claude/) or user-level (~/.claude/)
SCOPE="${1:---project}"

if [ "$SCOPE" = "--global" ] || [ "$SCOPE" = "-g" ]; then
  TARGET_DIR="$HOME/.claude"
  echo "Installing globally to $TARGET_DIR"
else
  TARGET_DIR=".claude"
  echo "Installing to project directory: $(pwd)/$TARGET_DIR"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$TARGET_DIR" = ".claude" ] && [ "$(pwd)" = "$SCRIPT_DIR" ]; then
  echo "Tip: project-level install writes to the CURRENT working directory."
  echo "     Run this script from the project where you want to use PAB."
fi

# Install skill
mkdir -p "$TARGET_DIR/skills/product-advisory-board"
cp "$SCRIPT_DIR/skills/product-advisory-board/SKILL.md" "$TARGET_DIR/skills/product-advisory-board/"
echo "  ✓ Skill installed to $TARGET_DIR/skills/product-advisory-board/"

# Install agents
mkdir -p "$TARGET_DIR/agents"
for agent in "$SCRIPT_DIR"/agents/pab-*.md; do
  cp "$agent" "$TARGET_DIR/agents/"
done
echo "  ✓ 9 agent definitions installed to $TARGET_DIR/agents/"

echo ""
echo "Done! Try it:"
echo "  /product-advisory-board Should we build B2B or B2C first?"
echo "  /agents   # should list pab-scout, pab-red-team, and other PAB agents"
