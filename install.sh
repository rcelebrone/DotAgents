#!/bin/bash

# DotAgents Unified Installer
# Suporta: Antigravity (IDE & CLI), Claude Code, Cursor AI
# Função: Instalar a squad e se auto-destruir para limpar o repositório.

set -e

echo "================================================================="
echo "🚀 DotAgents — Instalador Unificado da Squad Multi-Agente"
echo "================================================================="
echo ""
echo "Selecione a ferramenta de IA que você utiliza neste projeto:"
echo "1) Antigravity (IDE e CLI)"
echo "2) Claude Code"
echo "3) Cursor AI"
echo ""

if [ "$1" == "--antigravity" ] || [ "$1" == "1" ]; then
    OPTION=1
elif [ "$1" == "--claude" ] || [ "$1" == "2" ]; then
    OPTION=2
elif [ "$1" == "--cursor" ] || [ "$1" == "3" ]; then
    OPTION=3
else
    read -p "Digite a opção [1-3]: " OPTION
fi

# Diretório onde o instalador e os arquivos base estão (pasta DotAgents clonada)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Repositório de destino onde o projeto foi clonado (pai do SCRIPT_DIR)
DEST_DIR="$(dirname "$SCRIPT_DIR")"
AGENTS_SRC="$SCRIPT_DIR/agents"
SKILLS_SRC="$SCRIPT_DIR/skills"
COMMANDS_SRC="$SCRIPT_DIR/commands"
MEMORYS_SRC="$SCRIPT_DIR/memorys"

# Função para instalar a memória viva na raiz do projeto
install_memorys() {
    if [ -d "$MEMORYS_SRC" ]; then
        if [ ! -d "$DEST_DIR/memorys" ]; then
            echo "📦 Instalando Memorys na raiz do projeto..."
            mkdir -p "$DEST_DIR/memorys/implementations"
            cp -r "$MEMORYS_SRC"/* "$DEST_DIR/memorys/"
            echo "  ✅ Diretório 'memorys/' criado na raiz."
        else
            echo "ℹ️ Diretório 'memorys/' já existe na raiz. Apenas garantindo arquivos base se ausentes."
            cp -rn "$MEMORYS_SRC"/* "$DEST_DIR/memorys/" 2>/dev/null || true
        fi
    fi
}

# Configuração de Variáveis por Ferramenta
case $OPTION in
    1)
        TARGET_DIR="$DEST_DIR/.agents"
        AGENTS_ROOT=".agents"
        MANAGER_FILE="$DEST_DIR/AGENTS.md" # Padrão oficial do Antigravity CLI e IDE
        TOOL_NAME="Antigravity"
        ;;
    2)
        TARGET_DIR="$DEST_DIR/.claude"
        AGENTS_ROOT=".claude"
        MANAGER_FILE="$DEST_DIR/CLAUDE.md"
        TOOL_NAME="Claude Code"
        ;;
    3)
        TARGET_DIR="$DEST_DIR/.cursor"
        RULES_DIR="$TARGET_DIR/rules"
        AGENTS_ROOT=".cursor"
        MANAGER_FILE="$DEST_DIR/CURSOR.md"
        TOOL_NAME="Cursor AI"
        ;;
    *)
        echo "❌ Opção inválida. Execução cancelada."
        exit 1
        ;;
esac

echo "-----------------------------------------------------------------"
echo "⚙️ Configurando o ecossistema para $TOOL_NAME..."
echo "-----------------------------------------------------------------"

# =====================================================================
# INSTALAÇÃO CURSOR AI (Usa padrão .mdc nas rules)
# =====================================================================
if [ "$OPTION" -eq 3 ]; then
    mkdir -p "$RULES_DIR"
    mkdir -p "$TARGET_DIR/skills"

    install_as_mdc() {
        local src_file=$1
        local dest_dir=$2
        local always_apply=$3
        local description=$4

        local filename=$(basename "$src_file" .md)
        local dest_file="$dest_dir/$filename.mdc"

        # Escrevendo o Frontmatter exigido pelo Cursor
        echo "---" > "$dest_file"
        echo "description: \"$description\"" >> "$dest_file"
        echo "globs: \"*\"" >> "$dest_file"
        echo "alwaysApply: $always_apply" >> "$dest_file"
        echo "---" >> "$dest_file"
        echo "" >> "$dest_file"
        
        # Copia ignorando o frontmatter original do arquivo .md
        if head -n 1 "$src_file" | grep -q "^---"; then
            sed '1 { /^---/ { :a N; /\n---/! ba; d; } }' "$src_file" >> "$dest_file"
        else
            cat "$src_file" >> "$dest_file"
        fi
        
        # Troca os placeholders de diretório
        sed -i.bak "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" "$dest_file" && rm -f "$dest_file.bak"
        echo "  ✅ Instalado (Rule): $filename.mdc"
    }

    if [ -d "$AGENTS_SRC" ]; then
        echo "📦 Instalando Agents..."
        for f in "$AGENTS_SRC"/*.md; do
            name=$(basename "$f" .md)
            install_as_mdc "$f" "$RULES_DIR" "false" "Persona of the $name agent"
        done
    fi

    if [ -d "$COMMANDS_SRC" ]; then
        echo "📦 Instalando Commands & Workflows..."
        for f in "$COMMANDS_SRC"/*.md; do
            name=$(basename "$f" .md)
            is_orch="false"
            [ "$name" == "manager" ] && is_orch="true"
            install_as_mdc "$f" "$RULES_DIR" "$is_orch" "Workflow for $name"
        done
    fi

    if [ -d "$SKILLS_SRC" ]; then
        echo "📦 Copiando Skills..."
        cp -r "$SKILLS_SRC"/* "$TARGET_DIR/skills/"
        find "$TARGET_DIR/skills/" -type f -name "*.md" -exec sed -i.bak "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" {} +
        # Cursor não suporta o trigger do antigravity
        find "$TARGET_DIR/skills/" -type f -name "*.md" -exec sed -i.bak "/^[[:space:]]*trigger:[[:space:]]*always_on/d" {} +
        find "$TARGET_DIR/skills/" -type f -name "*.md.bak" -delete
    fi

    install_memorys

    if [ -f "$RULES_DIR/manager.mdc" ]; then
        echo "🔗 Criando link simbólico para $(basename "$MANAGER_FILE")..."
        (cd "$DEST_DIR" && ln -sf "$AGENTS_ROOT/rules/manager.mdc" "$(basename "$MANAGER_FILE")")
    fi

# =====================================================================
# INSTALAÇÃO PADRÃO (Antigravity, Claude)
# =====================================================================
else
    mkdir -p "$TARGET_DIR/agents"
    mkdir -p "$TARGET_DIR/skills"
    mkdir -p "$TARGET_DIR/commands"

    copy_and_replace() {
        local src=$1
        local dest=$2
        cp "$src" "$dest"
        
        # Substitui caminho raiz dinamicamente
        sed -i.bak "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" "$dest" && rm -f "$dest.bak"
        
        # Claude não suporta/precisa do 'trigger: always_on' do Antigravity
        if [ "$OPTION" -eq 2 ]; then
            sed -i.bak "/^[[:space:]]*trigger:[[:space:]]*always_on/d" "$dest" && rm -f "$dest.bak"
        fi
    }

    if [ -d "$AGENTS_SRC" ]; then
        echo "📦 Instalando Agents..."
        for f in "$AGENTS_SRC"/*.md; do
            copy_and_replace "$f" "$TARGET_DIR/agents/$(basename "$f")"
            echo "  ✅ Instalado: $(basename "$f")"
        done
    fi

    if [ -d "$SKILLS_SRC" ]; then
        echo "📦 Instalando Skills..."
        cp -r "$SKILLS_SRC"/* "$TARGET_DIR/skills/"
        find "$TARGET_DIR/skills/" -type f -name "*.md" -exec sed -i.bak "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" {} +
        if [ "$OPTION" -eq 2 ]; then
            find "$TARGET_DIR/skills/" -type f -name "*.md" -exec sed -i.bak "/^[[:space:]]*trigger:[[:space:]]*always_on/d" {} +
        fi
        find "$TARGET_DIR/skills/" -type f -name "*.md.bak" -delete
    fi

    if [ -d "$COMMANDS_SRC" ]; then
        echo "📦 Instalando Commands..."
        for f in "$COMMANDS_SRC"/*.md; do
            copy_and_replace "$f" "$TARGET_DIR/commands/$(basename "$f")"
        done
    fi

    install_memorys

    if [ -f "$TARGET_DIR/commands/manager.md" ]; then
        echo "🔗 Criando link simbólico para $(basename "$MANAGER_FILE")..."
        (cd "$DEST_DIR" && ln -sf "$AGENTS_ROOT/commands/manager.md" "$(basename "$MANAGER_FILE")")
    fi
fi

# =====================================================================
# POST-INSTALL CLEANUP (Auto-destruição da pasta original)
# =====================================================================
echo "-----------------------------------------------------------------"
echo "🧹 Limpando arquivos residuais de instalação..."
if [ -n "$SCRIPT_DIR" ] && [ "$SCRIPT_DIR" != "/" ] && [ "$SCRIPT_DIR" != "$DEST_DIR" ]; then
    rm -rf "$SCRIPT_DIR"
    echo "  ✅ Pasta 'DotAgents/' e instaladores removidos com sucesso."
else
    echo "  ⚠️ Ignorando remoção da pasta base por precaução de segurança (não é subdiretório)."
fi

echo "-----------------------------------------------------------------"
echo "✨ Instalação Concluída!"
echo "Sua squad DotAgents está operante para $TOOL_NAME."
if [ "$OPTION" -eq 1 ]; then
    echo "Abra o aplicativo Desktop ou digite 'agy' no terminal para começar!"
fi
echo "Dica: Peça para a IA executar as instruções do 'commands/dot-agent-bootstrap.md'."
echo "-----------------------------------------------------------------"
