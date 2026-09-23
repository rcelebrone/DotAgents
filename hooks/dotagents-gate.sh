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
if grep -lE '^\*\*Status:\*\*.*(planejada|em-implementacao|em-verificacao|em-qa|em-security|em-review|aprovada-para-entrega)' "$ROOT"/docs/todo/*/task.md >/dev/null 2>&1; then
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
