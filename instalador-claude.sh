#!/bin/bash

# DotAgents Installer for Claude Code
# This script copies agents, skills, and commands to the .claude directory.

set -e

# Target directory
TARGET_DIR=".claude"
AGENTS_ROOT=".claude"

# Source directories (relative to script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SRC="$SCRIPT_DIR/agents"
SKILLS_SRC="$SCRIPT_DIR/skills"
COMMANDS_SRC="$SCRIPT_DIR/commands"
MEMORYS_SRC="$SCRIPT_DIR/memorys"

echo "-----------------------------------------------"
echo "🚀 Installing DotAgents to $TARGET_DIR"
echo "-----------------------------------------------"

# Ensure target directories exist
mkdir -p "$TARGET_DIR/agents"
mkdir -p "$TARGET_DIR/skills"
mkdir -p "$TARGET_DIR/commands"

# Function to copy and replace placeholder
copy_and_replace() {
    local src=$1
    local dest=$2
    cp "$src" "$dest"
    sed -i "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" "$dest"
    # Remove Antigravity specific trigger (flexible regex)
    sed -i "/^[[:space:]]*trigger:[[:space:]]*always_on/d" "$dest"
}

# 1. Install Agents
if [ -d "$AGENTS_SRC" ]; then
    echo "📦 Installing Agents..."
    for f in "$AGENTS_SRC"/*.md; do
        copy_and_replace "$f" "$TARGET_DIR/agents/$(basename "$f")"
    done
    echo "  ✅ Installed Agents to $TARGET_DIR/agents/"
fi

# 2. Install Skills
if [ -d "$SKILLS_SRC" ]; then
    echo "📦 Installing Skills..."
    cp -r "$SKILLS_SRC"/* "$TARGET_DIR/skills/"
    find "$TARGET_DIR/skills/" -type f -name "*.md" -exec sed -i "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" {} +
    find "$TARGET_DIR/skills/" -type f -name "*.md" -exec sed -i "/^[[:space:]]*trigger:[[:space:]]*always_on/d" {} +
    echo "  ✅ Installed Skills to $TARGET_DIR/skills/"
fi

# 3. Install Commands
if [ -d "$COMMANDS_SRC" ]; then
    echo "📦 Installing Commands..."
    for f in "$COMMANDS_SRC"/*.md; do
        copy_and_replace "$f" "$TARGET_DIR/commands/$(basename "$f")"
    done
    echo "  ✅ Installed Commands to $TARGET_DIR/commands/"
fi

# 4. Install Memorys (Shared at project root)
if [ -d "$MEMORYS_SRC" ]; then
    if [ ! -d "memorys" ]; then
        echo "📦 Installing Memorys to project root..."
        mkdir -p "memorys/implementations"
        cp -r "$MEMORYS_SRC"/* "memorys/"
        echo "  ✅ Installed Memorys at project root"
    else
        echo "ℹ️ Memorys directory already exists at root. Skipping initial copy."
    fi
fi

# 5. Set up CLAUDE.md (Main Manager)
if [ -f "$COMMANDS_SRC/manager.md" ]; then
    echo "🔗 Linking manager to CLAUDE.md..."
    copy_and_replace "$COMMANDS_SRC/manager.md" "CLAUDE.md"
    echo "  ✅ CLAUDE.md created from manager.md"
fi

# 6. Add DotAgents to .gitignore
if [ -d "DotAgents" ]; then
    if ! grep -q "^DotAgents/" .gitignore 2>/dev/null; then
        echo -e "\n# DotAgents\nDotAgents/" >> .gitignore
        echo "  ✅ Added DotAgents/ to .gitignore"
    fi
fi

echo "-----------------------------------------------"
echo "✨ Installation complete!"
echo "Your Claude Code squad is ready in $TARGET_DIR/"
echo "-----------------------------------------------"
