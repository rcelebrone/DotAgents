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
get_codex_files() {
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$IN" | python3 -c 'import json,re,sys
try:
 import shlex
 d=json.load(sys.stdin); ti=d.get("tool_input") or {}; cmd=ti.get("command", "")
 if d.get("tool_name") == "apply_patch" or "*** Begin Patch" in cmd:
  for line in cmd.splitlines():
   if line.startswith(("*** Update File: ", "*** Add File: ", "*** Delete File: ", "*** Move to: ")): print(line.split(": ",1)[1])
 else:
  lexer=shlex.shlex(cmd, posix=True, punctuation_chars=";&|<>")
  lexer.whitespace_split=True; lexer.commenters=""
  tokens=list(lexer); segment=[]
  def paths(parts):
   if not parts: return
   command=parts[0].rsplit("/",1)[-1]
   args=[]; after_options=False
   for value in parts[1:]:
    if value == "--": after_options=True; continue
    if not after_options and value.startswith("-"): continue
    args.append(value)
   if command in ("touch", "rm", "truncate", "tee"):
    for value in args: print(value)
   elif command in ("cp", "mv", "install") and args:
    print(args[-1])
  index=0
  while index < len(tokens):
   token=tokens[index]
   if token and all(char in ";&|" for char in token):
    paths(segment); segment=[]
   elif ">" in token:
    paths(segment); segment=[]
    if index + 1 < len(tokens): print(tokens[index + 1]); index += 1
   else:
    segment.append(token)
   index += 1
  paths(segment)
except Exception: pass' 2>/dev/null
  fi
}
get_ws() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$IN" | jq -r '.workspacePaths[0] // empty' 2>/dev/null
  else
    printf '%s' "$IN" | sed -n 's/.*"workspacePaths"[[:space:]]*:[[:space:]]*\[[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null
  fi
}
if [ "$TARGET" = codex ]; then
  FILES=$(get_codex_files)
else
  FILE=$(get_file) || exit 0
  [ -z "$FILE" ] && exit 0
  FILES="$FILE"
fi
[ -z "$FILES" ] && exit 0
ROOT="${CLAUDE_PROJECT_DIR:-}"
if [ "$TARGET" = codex ]; then
  ROOT=$(printf '%s' "$IN" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("cwd", ""))' 2>/dev/null)
fi
if [ -z "$ROOT" ]; then
  WS=$(get_ws) || WS=""
  if [ -n "$WS" ] && [ -d "$WS" ]; then ROOT="$WS"; else ROOT="$PWD"; fi
fi
[ -f "$ROOT/docs/todo/.dotagents-bypass" ] && exit 0
# Allowlist: infra da squad, docs e memórias nunca bloqueiam
UNSAFE=0
OLD_IFS=$IFS
IFS='
'
set -f
for FILE in $FILES; do
  case "$FILE" in
    *.md|*/docs/*|docs/*|*/memories/*|memories/*|*/.claude/*|.claude/*|*/.agents/*|.agents/*|*/.cursor/*|.cursor/*|*/.codex/*|.codex/*|*CHANGELOG*|*.env.example) continue ;;
    *) UNSAFE=1 ;;
  esac
done
set +f
IFS=$OLD_IFS
[ "$UNSAFE" -eq 0 ] && exit 0
# Task ativa (status de trabalho ou compound pós-entrega) => permite
if grep -lE '^\*\*Status:\*\*.*(planejada|em-implementacao|em-verificacao|em-qa|em-security|em-review|aprovada-para-entrega|entregue)' "$ROOT"/docs/todo/*/task.md >/dev/null 2>&1; then
  exit 0
fi
REASON="DotAgents: nenhuma task ativa em docs/todo/*/task.md. Roteie a demanda pelo Manager (o PO/TL cria a task) ou registre opt-out formal ('sem squad' cria docs/todo/.dotagents-bypass)."
case "$TARGET" in
  claude)      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$REASON" ;;
  antigravity) printf '{"decision":"deny","reason":"%s"}\n' "$REASON" ;;
  cursor)      printf '{"permission":"deny","user_message":"%s"}\n' "$REASON" ;;
  codex)       printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$REASON" ;;
  *)           exit 0 ;;
esac
exit 0
