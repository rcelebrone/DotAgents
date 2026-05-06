#!/bin/bash

# DotAgents Installer for gemini-cli
# This script copies agents, skills, and commands to the .gemini directory.

set -e

# Target directory (usually ~/.gemini)
GEMINI_DIR="${GEMINI_DIR:-.gemini}"
AGENTS_ROOT=".gemini"

# Source directories (relative to script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SRC="$SCRIPT_DIR/agents"
SKILLS_SRC="$SCRIPT_DIR/skills"
COMMANDS_SRC="$SCRIPT_DIR/commands"
MEMORYS_SRC="$SCRIPT_DIR/memorys"

echo "-----------------------------------------------"
echo "🚀 Installing DotAgents to $GEMINI_DIR"
echo "-----------------------------------------------"

# Ensure target directories exist
mkdir -p "$GEMINI_DIR/agents"
mkdir -p "$GEMINI_DIR/skills"
mkdir -p "$GEMINI_DIR/commands"

# Function to copy and replace placeholder
copy_and_replace() {
    local src=$1
    local dest=$2
    cp "$src" "$dest"
    # Use different separator for sed to avoid conflict with paths
    sed -i "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" "$dest"
    # Remove Antigravity specific trigger (flexible regex)
    sed -i "/^[[:space:]]*trigger:[[:space:]]*always_on/d" "$dest"
}

# 1. Install Agents
if [ -d "$AGENTS_SRC" ]; then
    echo "📦 Installing Agents..."
    for agent_file in "$AGENTS_SRC"/*.md; do
        if [ -f "$agent_file" ]; then
            agent_name=$(basename "$agent_file")
            copy_and_replace "$agent_file" "$GEMINI_DIR/agents/$agent_name"
            echo "  ✅ Installed Agent: $agent_name"
        fi
    done
fi

# 2. Install Skills
if [ -d "$SKILLS_SRC" ]; then
    echo "📦 Installing Skills..."
    cp -r "$SKILLS_SRC"/* "$GEMINI_DIR/skills/"
    find "$GEMINI_DIR/skills/" -type f -name "*.md" -exec sed -i "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" {} +
    find "$GEMINI_DIR/skills/" -type f -name "*.md" -exec sed -i "/^[[:space:]]*trigger:[[:space:]]*always_on/d" {} +
    echo "  ✅ Installed Skills"
fi

# 3. Install Commands
if [ -d "$COMMANDS_SRC" ]; then
    echo "📦 Installing Commands..."
    for cmd_file in "$COMMANDS_SRC"/*.md; do
        if [ -f "$cmd_file" ]; then
            cmd_name=$(basename "$cmd_file")
            copy_and_replace "$cmd_file" "$GEMINI_DIR/commands/$cmd_name"
            echo "  ✅ Installed Command: $cmd_name"
        fi
    done
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

# 5. Set up GEMINI.md (Main Manager)
if [ -f "$COMMANDS_SRC/manager.md" ]; then
    echo "🔗 Linking manager to GEMINI.md..."
    copy_and_replace "$COMMANDS_SRC/manager.md" "GEMINI.md"
    echo "  ✅ GEMINI.md created from manager.md"
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
echo "You can now use your squad with gemini-cli."
echo "-----------------------------------------------"
