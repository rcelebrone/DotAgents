#!/bin/bash

# DotAgents Installer for Antigravity
# This script copies agents, skills, and commands to the .agents directory.

set -e

# Target directory
TARGET_DIR=".agents"
AGENTS_ROOT=".agents"

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
mkdir -p "$TARGET_DIR/rules"
mkdir -p "$TARGET_DIR/skills"
mkdir -p "$TARGET_DIR/commands"
mkdir -p "$TARGET_DIR/memorys"

# Function to copy and replace placeholder
copy_and_replace() {
    local src=$1
    local dest=$2
    cp "$src" "$dest"
    sed -i "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" "$dest"
}

# 1. Install Agents (as Rules)
if [ -d "$AGENTS_SRC" ]; then
    echo "📦 Installing Agents as Rules..."
    for f in "$AGENTS_SRC"/*.md; do
        copy_and_replace "$f" "$TARGET_DIR/rules/$(basename "$f")"
    done
    echo "  ✅ Installed Agents to $TARGET_DIR/rules/"
fi

# 2. Install Skills
if [ -d "$SKILLS_SRC" ]; then
    echo "📦 Installing Skills..."
    cp -r "$SKILLS_SRC"/* "$TARGET_DIR/skills/"
    find "$TARGET_DIR/skills/" -type f -name "*.md" -exec sed -i "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" {} +
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

# 4. Install Memorys
if [ -d "$MEMORYS_SRC" ]; then
    echo "📦 Installing Memorys..."
    cp -r "$MEMORYS_SRC"/* "$TARGET_DIR/memorys/"
    find "$TARGET_DIR/memorys/" -type f -name "*.md" -exec sed -i "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" {} +
    echo "  ✅ Installed Memorys to $TARGET_DIR/memorys/"
fi

# 5. Set up AG.md (Main Orchestrator)
if [ -f "$COMMANDS_SRC/orchestrator.md" ]; then
    echo "🔗 Linking orchestrator to AG.md..."
    copy_and_replace "$COMMANDS_SRC/orchestrator.md" "AG.md"
    echo "  ✅ AG.md created from orchestrator.md"
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
echo "Your Antigravity squad is ready in $TARGET_DIR/"
echo "-----------------------------------------------"
