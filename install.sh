#!/usr/bin/env bash

# DotAgents v2 — Instalador Unificado da Squad Multi-Agente
# Alvos: Antigravity (IDE & CLI), Claude Code, Cursor AI
# Idempotente: re-rodar atualiza os artefatos da squad sem tocar na memória viva.

set -euo pipefail

DOTAGENTS_VERSION="2.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OPTION=""
DEST_DIR=""
ASSUME_YES=0
PURGE=0
NO_HOOKS=0
CURSOR_NATIVE=0

usage() {
  cat <<EOF
DotAgents v${DOTAGENTS_VERSION} — instalador da squad multi-agente

Uso: install.sh --antigravity|--claude|--cursor [opções]

Alvos:
  --antigravity      Antigravity (IDE e CLI)  -> .agents/ + AGENTS.md
  --claude           Claude Code              -> .claude/ + CLAUDE.md
  --cursor           Cursor AI                -> .cursor/ + AGENTS.md

Opções:
  --dest <dir>       Diretório do projeto destino (default: diretório atual)
  --yes              Não perguntar confirmações (modo não interativo)
  --no-hooks         Não instalar o hook de enforcement
  --cursor-native    (Cursor) modo 'subagentes' em vez de 'persona-shift'
  --purge            Remover a pasta DotAgents/ ao final (default: preservar)
  --help             Esta ajuda
EOF
}

die()  { echo "❌ $*" >&2; exit 1; }
info() { echo "$*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --antigravity) OPTION=1 ;;
    --claude)      OPTION=2 ;;
    --cursor)      OPTION=3 ;;
    --dest)        shift; [ $# -gt 0 ] || die "--dest exige um diretório"; DEST_DIR="$1" ;;
    --yes)         ASSUME_YES=1 ;;
    --purge)       PURGE=1 ;;
    --no-hooks)    NO_HOOKS=1 ;;
    --cursor-native) CURSOR_NATIVE=1 ;;
    --help|-h)     usage; exit 0 ;;
    *)             die "Argumento desconhecido: $1 (use --help)" ;;
  esac
  shift
done

if [ -z "$OPTION" ]; then
  if [ -t 0 ]; then
    echo "Selecione a ferramenta de IA usada neste projeto:"
    echo "  1) Antigravity (IDE e CLI)"
    echo "  2) Claude Code"
    echo "  3) Cursor AI"
    read -r -p "Digite a opção [1-3]: " OPTION
    case "$OPTION" in 1|2|3) ;; *) die "Opção inválida." ;; esac
  else
    die "Nenhum alvo informado. Use --antigravity, --claude ou --cursor (--help para ajuda)."
  fi
fi

DEST_DIR="${DEST_DIR:-$PWD}"
DEST_DIR="$(cd "$DEST_DIR" 2>/dev/null && pwd)" || die "Diretório destino inexistente."
[ "$DEST_DIR" = "$SCRIPT_DIR" ] && die "O destino é a própria pasta DotAgents. Rode a partir da raiz do SEU projeto ou use --dest <dir>."

confirm() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  local r=""
  read -r -p "$1 [S/N]: " r || return 1
  case "$r" in S|s|Y|y|sim|SIM|Sim) return 0 ;; *) return 1 ;; esac
}

case "$OPTION" in
  1) TOOL_NAME="Antigravity"; AGENTS_ROOT=".agents"; ROOT_FILE="AGENTS.md"; DISPATCH_MODE="subagentes";    HOOK_TARGET="antigravity" ;;
  2) TOOL_NAME="Claude Code"; AGENTS_ROOT=".claude"; ROOT_FILE="CLAUDE.md"; DISPATCH_MODE="subagentes";    HOOK_TARGET="claude" ;;
  3) TOOL_NAME="Cursor AI";   AGENTS_ROOT=".cursor"; ROOT_FILE="AGENTS.md"; DISPATCH_MODE="persona-shift"; HOOK_TARGET="cursor"
     [ "$CURSOR_NATIVE" -eq 1 ] && DISPATCH_MODE="subagentes" ;;
esac
TARGET_DIR="$DEST_DIR/$AGENTS_ROOT"

echo "================================================================="
echo "🚀 DotAgents v${DOTAGENTS_VERSION} — ${TOOL_NAME}"
echo "   Destino  : $DEST_DIR"
echo "   Artefatos: $AGENTS_ROOT/ · memories/ · $ROOT_FILE (bloco gerido)"
echo "   Dispatch : $DISPATCH_MODE · Hooks: $([ "$NO_HOOKS" -eq 1 ] && echo "não" || echo "sim")"
echo "================================================================="
confirm "Instalar em $DEST_DIR?" || die "Instalação cancelada."

# ------------------------------------------------------------------ helpers

# Copia src -> dst substituindo os placeholders (portável BSD/GNU: nunca sed -i)
render_file() {
  mkdir -p "$(dirname "$2")"
  sed -e "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" -e "s|{{DISPATCH_MODE}}|$DISPATCH_MODE|g" "$1" > "$2"
}

render_tree_inplace() {
  find "$1" -type f -name "*.md" | while IFS= read -r f; do
    sed -e "s|{{AGENTS_ROOT}}|$AGENTS_ROOT|g" -e "s|{{DISPATCH_MODE}}|$DISPATCH_MODE|g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  done
}

# Traduz o frontmatter agnóstico (tools genéricas + model tier:*) para o alvo
translate_agent() {
  case "$OPTION" in
    2) awk '
        /^tools:/ {
          line=$0; sub(/^tools:[ \t]*\[/,"",line); sub(/\][ \t]*$/,"",line)
          n=split(line,t,","); out=""
          for(i=1;i<=n;i++){
            g=t[i]; gsub(/[ \t]/,"",g); m=""
            if(g=="read_file")m="Read"; else if(g=="grep_search")m="Grep"
            else if(g=="glob")m="Glob"; else if(g=="replace")m="Edit"
            else if(g=="write_file")m="Write"; else if(g=="run_shell_command")m="Bash"
            if(m!="") out=(out==""?m:out ", " m)
          }
          print "tools: " out; next
        }
        /^model:[ \t]*"tier:reasoning"/ {print "model: inherit"; next}
        /^model:[ \t]*"tier:speed"/     {print "model: sonnet";  next}
        {print}' "$1" > "$1.tmp" && mv "$1.tmp" "$1" ;;
    1) awk '
        /^tools:/ {next}
        /^model:[ \t]*"tier:reasoning"/ {print "model: pro";   print "subagent: true"; next}
        /^model:[ \t]*"tier:speed"/     {print "model: flash"; print "subagent: true"; next}
        {print}' "$1" > "$1.tmp" && mv "$1.tmp" "$1" ;;
    3) awk '
        /^tools:/ {next}
        /^model:[ \t]*"tier:/ {print "model: inherit"; next}
        {print}' "$1" > "$1.tmp" && mv "$1.tmp" "$1" ;;
  esac
}

# --------------------------------------------------------------- memórias

migrate_legacy_memorys() {
  if [ -d "$DEST_DIR/memorys" ] && [ ! -d "$DEST_DIR/memories" ]; then
    if confirm "Diretório legado 'memorys/' encontrado. Renomear para 'memories/'?"; then
      mv "$DEST_DIR/memorys" "$DEST_DIR/memories"
      info "  ✅ memorys/ -> memories/"
    else
      info "  ⚠️ 'memorys/' mantido. A squad v2 usa 'memories/' — recomenda-se migrar."
    fi
  fi
}

install_memories() {
  info "📦 Instalando memórias (memories/) — arquivos existentes são preservados..."
  mkdir -p "$DEST_DIR/memories/implementations" "$DEST_DIR/memories/templates"
  (cd "$SCRIPT_DIR/memories" && find . -type f) | while IFS= read -r rel; do
    rel="${rel#./}"
    if [ ! -f "$DEST_DIR/memories/$rel" ]; then
      render_file "$SCRIPT_DIR/memories/$rel" "$DEST_DIR/memories/$rel"
    fi
  done
}

# --------------------------------------------------- artefatos da squad

install_squad_files() {
  info "📦 Instalando agents, skills e commands em $AGENTS_ROOT/..."
  mkdir -p "$TARGET_DIR/agents" "$TARGET_DIR/skills" "$TARGET_DIR/commands"
  local f dst
  for f in "$SCRIPT_DIR"/agents/*.md; do
    dst="$TARGET_DIR/agents/$(basename "$f")"
    render_file "$f" "$dst"
    translate_agent "$dst"
  done
  cp -R "$SCRIPT_DIR/skills/." "$TARGET_DIR/skills/"
  render_tree_inplace "$TARGET_DIR/skills"
  for f in "$SCRIPT_DIR"/commands/*.md; do
    render_file "$f" "$TARGET_DIR/commands/$(basename "$f")"
  done
  info "  ✅ 7 agents (frontmatter traduzido p/ $TOOL_NAME) · 15 skills · 6 commands"
}

install_cursor_rule() {
  [ "$OPTION" -eq 3 ] || return 0
  mkdir -p "$TARGET_DIR/rules"
  cat > "$TARGET_DIR/rules/dotagents-manager.mdc" <<'EOF'
---
description: DotAgents — roteador da squad multi-agente. Sempre ativo.
alwaysApply: true
---

# 🤖 DotAgents — Squad ativa

Toda demanda neste repositório é regida pelo protocolo em `.cursor/commands/manager.md`.
Antes de responder qualquer solicitação: leia esse arquivo e siga o roteamento do Manager (classificação, estados e gates por artefato).
Personas: `.cursor/agents/` · Skills: `.cursor/skills/` · Comandos: `.cursor/commands/`.
**Esta regra vale DENTRO de modos nativos (plan/agent):** execute a intenção do comando ATRAVÉS da squad — planejar = personas produzindo o conteúdo do task.md; ao sair do modo somente-leitura, materialize-o em docs/todo/ antes de editar código.
Não implemente nada fora do fluxo da squad, salvo opt-out formal registrado (manager § Regra Inviolável Opt-out).
EOF
  info "  ✅ Regra sempre-ativa: $AGENTS_ROOT/rules/dotagents-manager.mdc"
}

# ------------------------------------------------- bloco raiz gerido

inject_root_block() {
  local file="$DEST_DIR/$ROOT_FILE"
  local block
  block="$(mktemp)"
  {
    echo "<!-- dotagents:begin v${DOTAGENTS_VERSION} — bloco gerido pelo DotAgents; NÃO edite manualmente. Atualize re-rodando o install.sh -->"
    [ "$OPTION" -eq 2 ] && echo "@.claude/commands/manager.md"
    echo "## 🤖 DotAgents — Squad Multi-Agente ativa"
    echo "Toda demanda neste repositório é regida pelo protocolo da squad em \`$AGENTS_ROOT/commands/manager.md\`."
    echo "Antes de responder qualquer solicitação: classifique, anuncie (📢) e garanta a task — na ordem do Manager."
    echo "**Esta regra vale DENTRO de /plan e de qualquer modo/comando nativo da ferramenta:** execute a intenção do comando ATRAVÉS da squad — planejar = personas produzindo o conteúdo do task.md; ao sair do modo somente-leitura, a primeira ação é materializá-lo em docs/todo/."
    echo "Não implemente nada fora do fluxo da squad, salvo opt-out formal registrado (manager § Regra Inviolável Opt-out)."
    echo "<!-- dotagents:end -->"
  } > "$block"

  if [ -L "$file" ]; then
    info "  ⚠️ $ROOT_FILE era um symlink (instalação v1) — convertendo para arquivo real."
    rm "$file"
  fi
  if [ ! -f "$file" ]; then
    cat "$block" > "$file"
  else
    # strip do bloco antigo (se houver) + prepend do novo no TOPO do arquivo
    local rest
    rest="$(mktemp)"
    if grep -q "dotagents:begin" "$file"; then
      awk '
        /<!-- dotagents:begin/ {skip=1; next}
        /<!-- dotagents:end/   {skip=0; next}
        !skip {print}
      ' "$file" > "$rest"
    else
      cat "$file" > "$rest"
    fi
    # remove linhas em branco iniciais do restante (garante idempotência byte-idêntica)
    sed '/./,$!d' "$rest" > "$rest.tmp" && mv "$rest.tmp" "$rest"
    if [ -s "$rest" ]; then
      { cat "$block"; echo ""; cat "$rest"; } > "$file.tmp" && mv "$file.tmp" "$file"
    else
      cat "$block" > "$file"
    fi
    rm -f "$rest"
  fi
  rm -f "$block"
  info "  ✅ Bloco de roteamento gerido no TOPO de $ROOT_FILE"
}

# ------------------------------------------------------------- hooks

print_claude_snippet() {
  cat <<EOF
  Adicione em $AGENTS_ROOT/settings.json:
  {"hooks":{"PreToolUse":[{"matcher":"Edit|Write|MultiEdit|NotebookEdit","hooks":[{"type":"command","command":"$1","timeout":10}]}],"UserPromptSubmit":[{"hooks":[{"type":"command","command":"$2","timeout":5}]}]}}
EOF
}

print_antigravity_snippet() {
  cat <<EOF
  Adicione em $AGENTS_ROOT/hooks.json (top-level é uma chave NOMEADA, não "hooks"):
  {"dotagents":{"enabled":true,"PreToolUse":[{"matcher":"write_to_file|replace_file_content|multi_replace_file_content","hooks":[{"type":"command","command":"$1","timeout":10}]}],"PreInvocation":[{"type":"command","command":"$2","timeout":5}]}}
EOF
}

print_cursor_snippet() {
  cat <<EOF
  Adicione em $AGENTS_ROOT/hooks.json:
  {"version":1,"hooks":{"preToolUse":[{"command":"$1"}],"sessionStart":[{"command":"$2"}]}}
EOF
}

merge_hooks_claude() {
  local gate="\$CLAUDE_PROJECT_DIR/$AGENTS_ROOT/hooks/dotagents-gate.sh claude"
  local remind="\$CLAUDE_PROJECT_DIR/$AGENTS_ROOT/hooks/dotagents-remind.sh claude"
  local settings="$TARGET_DIR/settings.json"
  if [ ! -f "$settings" ]; then
    cat > "$settings" <<EOF
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit|Write|MultiEdit|NotebookEdit",
        "hooks": [ { "type": "command", "command": "$gate", "timeout": 10 } ] }
    ],
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "$remind", "timeout": 5 } ] }
    ]
  }
}
EOF
    info "  ✅ Hooks registrados em $AGENTS_ROOT/settings.json (gate + remind)"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    local rc=0
    python3 - "$settings" "$gate" "$remind" <<'PY' || rc=$?
import json, sys
path, gate, remind = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(path) as f: data = json.load(f)
except Exception:
    sys.exit(3)
hooks = data.setdefault("hooks", {})
for ev in list(hooks):
    if isinstance(hooks[ev], list):
        hooks[ev] = [e for e in hooks[ev] if "dotagents-" not in json.dumps(e)]
        if not hooks[ev]:
            del hooks[ev]
hooks.setdefault("PreToolUse", []).append({"matcher": "Edit|Write|MultiEdit|NotebookEdit",
    "hooks": [{"type": "command", "command": gate, "timeout": 10}]})
hooks.setdefault("UserPromptSubmit", []).append(
    {"hooks": [{"type": "command", "command": remind, "timeout": 5}]})
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
    if [ "$rc" -eq 0 ]; then
      info "  ✅ Hooks mesclados em $AGENTS_ROOT/settings.json (gate + remind; entradas dotagents antigas substituídas)"
    else
      info "  ⚠️ Não foi possível mesclar $AGENTS_ROOT/settings.json (JSON inválido?) — registre manualmente:"
      print_claude_snippet "$gate" "$remind"
    fi
  else
    info "  ⚠️ python3 ausente e $AGENTS_ROOT/settings.json existe — registre manualmente:"
    print_claude_snippet "$gate" "$remind"
  fi
}

merge_hooks_antigravity() {
  local gate="$AGENTS_ROOT/hooks/dotagents-gate.sh antigravity"
  local remind="$AGENTS_ROOT/hooks/dotagents-remind.sh antigravity"
  local hooksfile="$TARGET_DIR/hooks.json"
  if [ ! -f "$hooksfile" ]; then
    cat > "$hooksfile" <<EOF
{
  "dotagents": {
    "enabled": true,
    "PreToolUse": [
      { "matcher": "write_to_file|replace_file_content|multi_replace_file_content",
        "hooks": [ { "type": "command", "command": "$gate", "timeout": 10 } ] }
    ],
    "PreInvocation": [
      { "type": "command", "command": "$remind", "timeout": 5 }
    ]
  }
}
EOF
    info "  ✅ Hooks registrados em $AGENTS_ROOT/hooks.json (chave 'dotagents'; valide com /hooks ou 'agy inspect')"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    local rc=0
    python3 - "$hooksfile" "$gate" "$remind" <<'PY' || rc=$?
import json, sys
path, gate, remind = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(path) as f: data = json.load(f)
except Exception:
    sys.exit(3)
# expurga resíduos dotagents fora da nossa chave (ex.: schema inválido do v2.0.0 sob "hooks")
for name in list(data):
    v = data[name]
    if name == "dotagents" or not isinstance(v, dict):
        continue
    for ev in list(v):
        if isinstance(v[ev], list):
            v[ev] = [e for e in v[ev] if "dotagents-" not in json.dumps(e)]
            if not v[ev]:
                del v[ev]
    if not v:
        del data[name]
data["dotagents"] = {"enabled": True,
    "PreToolUse": [{"matcher": "write_to_file|replace_file_content|multi_replace_file_content",
                    "hooks": [{"type": "command", "command": gate, "timeout": 10}]}],
    "PreInvocation": [{"type": "command", "command": remind, "timeout": 5}]}
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
    if [ "$rc" -eq 0 ]; then
      info "  ✅ Hooks mesclados em $AGENTS_ROOT/hooks.json (chave 'dotagents' atualizada; valide com /hooks ou 'agy inspect')"
    else
      info "  ⚠️ Não foi possível mesclar $AGENTS_ROOT/hooks.json (JSON inválido?) — registre manualmente:"
      print_antigravity_snippet "$gate" "$remind"
    fi
  else
    info "  ⚠️ python3 ausente e $AGENTS_ROOT/hooks.json existe — registre manualmente:"
    print_antigravity_snippet "$gate" "$remind"
  fi
}

merge_hooks_cursor() {
  local gate="$AGENTS_ROOT/hooks/dotagents-gate.sh cursor"
  local remind="$AGENTS_ROOT/hooks/dotagents-remind.sh cursor"
  local hooksfile="$TARGET_DIR/hooks.json"
  if [ ! -f "$hooksfile" ]; then
    cat > "$hooksfile" <<EOF
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      { "command": "$gate" }
    ],
    "sessionStart": [
      { "command": "$remind" }
    ]
  }
}
EOF
    info "  ✅ Hooks registrados em $AGENTS_ROOT/hooks.json (gate + remind)"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    local rc=0
    python3 - "$hooksfile" "$gate" "$remind" <<'PY' || rc=$?
import json, sys
path, gate, remind = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(path) as f: data = json.load(f)
except Exception:
    sys.exit(3)
data.setdefault("version", 1)
h = data.setdefault("hooks", {})
for ev in list(h):
    if isinstance(h[ev], list):
        h[ev] = [e for e in h[ev] if "dotagents-" not in json.dumps(e)]
        if not h[ev]:
            del h[ev]
h.setdefault("preToolUse", []).append({"command": gate})
h.setdefault("sessionStart", []).append({"command": remind})
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
    if [ "$rc" -eq 0 ]; then
      info "  ✅ Hooks mesclados em $AGENTS_ROOT/hooks.json (gate + remind)"
    else
      info "  ⚠️ Não foi possível mesclar $AGENTS_ROOT/hooks.json (JSON inválido?) — registre manualmente:"
      print_cursor_snippet "$gate" "$remind"
    fi
  else
    info "  ⚠️ python3 ausente e $AGENTS_ROOT/hooks.json existe — registre manualmente:"
    print_cursor_snippet "$gate" "$remind"
  fi
}

install_hook() {
  if [ "$NO_HOOKS" -eq 1 ]; then info "⏭️ Hooks desativados (--no-hooks)."; return 0; fi
  info "🔒 Instalando hooks de enforcement (fail-open): gate de escrita + lembrete por prompt..."
  mkdir -p "$TARGET_DIR/hooks"
  cat > "$TARGET_DIR/hooks/dotagents-gate.sh" <<'HOOK'
#!/bin/sh
# DotAgents gate (PreToolUse): nega edição de CÓDIGO quando não há task ativa.
# FAIL-OPEN: qualquer erro ou dado ausente => permite.
# Escape: docs/todo/.dotagents-bypass (criado apenas via opt-out formal "sem squad" — manager § Opt-out).
TARGET="${1:-claude}"
IN=$(cat 2>/dev/null) || exit 0
get_file() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$IN" | jq -r '.tool_input.file_path // .tool_input.path // .toolCall.args.TargetFile // .input.file_path // empty' 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$IN" | python3 -c 'import sys,json
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input") or {}
    tc = (d.get("toolCall") or {}).get("args") or {}
    inp = d.get("input") or {}
    print(ti.get("file_path") or ti.get("path") or tc.get("TargetFile") or inp.get("file_path") or "")
except Exception:
    pass' 2>/dev/null
  fi
}
get_ws() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$IN" | jq -r '.workspacePaths[0] // empty' 2>/dev/null
  else
    printf '%s' "$IN" | sed -n 's/.*"workspacePaths"[[:space:]]*:[[:space:]]*\[[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null
  fi
}
FILE=$(get_file) || exit 0
[ -z "$FILE" ] && exit 0
ROOT="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$ROOT" ]; then
  WS=$(get_ws) || WS=""
  if [ -n "$WS" ] && [ -d "$WS" ]; then ROOT="$WS"; else ROOT="$PWD"; fi
fi
[ -f "$ROOT/docs/todo/.dotagents-bypass" ] && exit 0
# Allowlist: infra da squad, docs e memórias nunca bloqueiam
case "$FILE" in
  *.md|*/docs/*|docs/*|*/memories/*|memories/*|*/.claude/*|.claude/*|*/.agents/*|.agents/*|*/.cursor/*|.cursor/*|*CHANGELOG*|*.env.example) exit 0 ;;
esac
# Task ativa (status de trabalho) => permite
if grep -lE '^\*\*Status:\*\*.*(planejada|em-implementacao|em-qa|em-security|em-review|aprovada-para-entrega)' "$ROOT"/docs/todo/*/task.md >/dev/null 2>&1; then
  exit 0
fi
REASON="DotAgents: nenhuma task ativa em docs/todo/*/task.md. Roteie a demanda pelo Manager (o PO/TL cria a task) ou registre opt-out formal ('sem squad' cria docs/todo/.dotagents-bypass)."
case "$TARGET" in
  claude)      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$REASON" ;;
  antigravity) printf '{"decision":"deny","reason":"%s"}\n' "$REASON" ;;
  cursor)      printf '{"permission":"deny","user_message":"%s"}\n' "$REASON" ;;
  *)           exit 0 ;;
esac
exit 0
HOOK
  chmod +x "$TARGET_DIR/hooks/dotagents-gate.sh"
  cat > "$TARGET_DIR/hooks/dotagents-remind.sh" <<'HOOK2'
#!/bin/sh
# DotAgents remind: reinjeta o protocolo da squad a cada prompt/invocação do modelo.
# Claude: UserPromptSubmit (stdout vira contexto) · Antigravity: PreInvocation (injectSteps)
# Cursor: sessionStart (additional_context). FAIL-OPEN: qualquer erro => exit 0 sem output.
TARGET="${1:-claude}"
IN=$(cat 2>/dev/null) || IN=""
case "$TARGET" in antigravity) AR=".agents" ;; cursor) AR=".cursor" ;; *) AR=".claude" ;; esac
ROOT="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$ROOT" ]; then
  WS=$(printf '%s' "$IN" | sed -n 's/.*"workspacePaths"[[:space:]]*:[[:space:]]*\[[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null)
  if [ -n "$WS" ] && [ -d "$WS" ]; then ROOT="$WS"; else ROOT="$PWD"; fi
fi
TASK="nenhuma task ativa — toda escrita de codigo exige task criada pelo fluxo"
F=$(grep -lE '^\*\*Status:\*\*.*(em-refinamento|spec-aprovada|planejada|em-implementacao|em-qa|em-security|em-review|aprovada-para-entrega)' "$ROOT"/docs/todo/*/task.md 2>/dev/null | head -n 1)
if [ -n "$F" ]; then
  S=$(grep -m1 '^\*\*Status:\*\*' "$F" 2>/dev/null | sed -e 's/^\*\*Status:\*\* *//' -e 's/<!--.*-->//' | tr -d '"\\' | tr -s ' ')
  TASK="task ativa: $(basename "$(dirname "$F")") ($S) — retome pelo manager (§ Estados)"
fi
case "$TARGET" in
  antigravity)
    # Política: emitir SEMPRE (a chamada de modelo que gera o plano é tardia no loop do /plan).
    # Para emitir só na 1ª invocação, descomente a linha abaixo:
    # N=$(printf '%s' "$IN" | sed -n 's/.*"invocationNum"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p'); [ "${N:-0}" -gt 0 ] && exit 0
    printf '{"injectSteps":[{"ephemeralMessage":"DotAgents: protocolo da squad ativo (%s/commands/manager.md) — classifique, anuncie a persona e garanta o task.md antes de agir; vale DENTRO de /plan e comandos nativos (plano = personas produzindo o task.md). Estado: %s."}]}\n' "$AR" "$TASK"
    ;;
  cursor)
    printf '{"additional_context":"[DotAgents] Protocolo da squad ativo — toda demanda é regida por %s/commands/manager.md. 1) Classifique, anuncie a persona e garanta o task.md ANTES de agir. 2) Vale DENTRO de modos nativos (plan/agent): planejar = personas produzindo o conteudo do task.md; ao sair do modo somente-leitura, materialize-o antes de editar codigo. 3) Estado: %s."}\n' "$AR" "$TASK"
    ;;
  *)
    printf '[DotAgents] Protocolo da squad ativo — esta demanda é regida por %s/commands/manager.md.\n' "$AR"
    printf '1) Classifique, anuncie a persona (📢) e garanta o task.md ANTES de agir.\n'
    printf '2) Vale DENTRO de comandos nativos (/plan, modo de planejamento): execute a intenção do comando ATRAVÉS da squad — planejar = personas produzindo o conteúdo do task.md; ao sair do plan mode, a primeira ação é materializá-lo.\n'
    printf '3) Estado: %s.\n' "$TASK"
    ;;
esac
exit 0
HOOK2
  chmod +x "$TARGET_DIR/hooks/dotagents-remind.sh"
  info "  ✅ Gate: $AGENTS_ROOT/hooks/dotagents-gate.sh · Remind: $AGENTS_ROOT/hooks/dotagents-remind.sh"
  case "$OPTION" in
    1) merge_hooks_antigravity ;;
    2) merge_hooks_claude ;;
    3) merge_hooks_cursor ;;
  esac
}

# --------------------------------------------------------- finalização

suggest_gitignore() {
  local gi="$DEST_DIR/.gitignore"
  local entry="docs/todo/.dotagents-bypass"
  if [ -f "$gi" ] && grep -qxF "$entry" "$gi" 2>/dev/null; then return 0; fi
  if confirm "Adicionar '$entry' ao .gitignore do projeto?"; then
    echo "$entry" >> "$gi"
    info "  ✅ .gitignore atualizado"
  fi
}

stamp_version() {
  cat > "$TARGET_DIR/.dotagents-version" <<EOF
version=$DOTAGENTS_VERSION
tool=$TOOL_NAME
dispatch=$DISPATCH_MODE
installed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
}

purge_source() {
  if [ "$PURGE" -ne 1 ]; then
    info "ℹ️ Pasta DotAgents/ preservada (para atualizar: git pull + re-rodar o install). Use --purge para removê-la."
    return 0
  fi
  if [ -n "$SCRIPT_DIR" ] && [ "$SCRIPT_DIR" != "/" ] && [ "$SCRIPT_DIR" != "$DEST_DIR" ]; then
    rm -rf "$SCRIPT_DIR"
    info "🧹 Pasta DotAgents/ removida (--purge)."
  else
    info "⚠️ Remoção da pasta base ignorada por precaução."
  fi
}

# ---------------------------------------------------------------- main

migrate_legacy_memorys
install_memories
install_squad_files
install_cursor_rule
inject_root_block
install_hook
suggest_gitignore
stamp_version
purge_source

echo "-----------------------------------------------------------------"
echo "✨ Instalação concluída — squad DotAgents v${DOTAGENTS_VERSION} operante para $TOOL_NAME."
case "$OPTION" in
  1) echo "Próximo passo: abra o Antigravity ('agy') e peça: \"Execute as instruções de .agents/commands/dot-agent-bootstrap.md\"" ;;
  2) echo "Próximo passo: abra o Claude Code e rode: /dot-agent-bootstrap" ;;
  3) echo "Próximo passo: abra o Cursor e peça: \"Execute as instruções de .cursor/commands/dot-agent-bootstrap.md\"" ;;
esac
echo "-----------------------------------------------------------------"
