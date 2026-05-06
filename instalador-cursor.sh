#!/bin/bash

# DotAgents Installer for Cursor AI
# This script copies agents and commands to .cursor/rules/ as .mdc files.

set -e

# Target directory
TARGET_DIR=".cursor"
RULES_DIR="$TARGET_DIR/rules"
AGENTS_ROOT=".cursor"

# Source directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SRC="$SCRIPT_DIR/agents"
COMMANDS_SRC="$SCRIPT_DIR/commands"
SKILLS_SRC="$SCRIPT_DIR/skills"
MEMORYS_SRC="$SCRIPT_DIR/memorys"

echo "-----------------------------------------------"
echo "🚀 Installing DotAgents to $TARGET_DIR"
echo "-----------------------------------------------"

mkdir -p "$RULES_DIR"
mkdir -p "$TARGET_DIR/skills"
mkdir -p "$TARGET_DIR/memorys"

# Function to convert .md to .mdc with frontmatter and replace placeholder
install_as_mdc() {
    local src_file=$1
    local dest_dir=$2
    local always_apply=$3
    local description=$4

    local filename=$(basename "$src_file" .md)
    local dest_file="$dest_dir/$filename.mdc"

    echo "---
description: \"$description\"
globs: \"\"
alwaysApply: $always_apply
---
" > "$dest_file"
    
    # Append content skipping the original frontmatter if it exists
    if head -n 1 "$src_file" | grep -q "^---"; then
        # Skip everything between the first and second ---
        sed '1 { /^---/ { :a N; /\n---/! ba; d } }' "$src_file" >> "$dest_file"
    else
        cat "$src_file" >> "$dest_file"
    fi
    
    # Replace placeholder
    sed -i "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" "$dest_file"
    
    echo "  ✅ Installed: $filename.mdc"
}

# 1. Install Agents
if [ -d "$AGENTS_SRC" ]; then
    echo "📦 Installing Agents as Rules..."
    for f in "$AGENTS_SRC"/*.md; do
        name=$(basename "$f" .md)
        install_as_mdc "$f" "$RULES_DIR" "false" "Persona of the $name agent"
    done
fi

# 2. Install Commands
if [ -d "$COMMANDS_SRC" ]; then
    echo "📦 Installing Commands as Rules..."
    for f in "$COMMANDS_SRC"/*.md; do
        name=$(basename "$f" .md)
        is_orch="false"
        [ "$name" == "manager" ] && is_orch="true"
        install_as_mdc "$f" "$RULES_DIR" "$is_orch" "Workflow for $name"
    done
fi

# 3. Install Skills & Memorys (Shared at project root)
if [ -d "$SKILLS_SRC" ]; then
    echo "📦 Copying Skills..."
    cp -r "$SKILLS_SRC"/* "$TARGET_DIR/skills/"
    find "$TARGET_DIR/skills/" -type f -name "*.md" -exec sed -i "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" {} +
    find "$TARGET_DIR/skills/" -type f -name "*.md" -exec sed -i "/^[[:space:]]*trigger:[[:space:]]*always_on/d" {} +
fi

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

# 4. Add DotAgents to .gitignore
if [ -d "DotAgents" ]; then
    if ! grep -q "^DotAgents/" .gitignore 2>/dev/null; then
        echo -e "\n# DotAgents\nDotAgents/" >> .gitignore
        echo "  ✅ Added DotAgents/ to .gitignore"
    fi
fi

echo "-----------------------------------------------"
echo "✨ Installation complete!"
echo "Your Cursor AI squad is ready in $TARGET_DIR/"
echo "-----------------------------------------------"
---------------"
