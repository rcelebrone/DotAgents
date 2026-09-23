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
F=$(grep -lE '^\*\*Status:\*\*.*(em-refinamento|spec-aprovada|planejada|em-implementacao|em-verificacao|em-qa|em-security|em-review|aprovada-para-entrega)' "$ROOT"/docs/todo/*/task.md 2>/dev/null | head -n 1)
if [ -n "$F" ]; then
  S=$(grep -m1 '^\*\*Status:\*\*' "$F" 2>/dev/null | sed -e 's/^\*\*Status:\*\* *//' -e 's/<!--.*-->//' | tr -d '"\\' | tr -s ' ')
  TASK="task ativa: $(basename "$(dirname "$F")") ($S) — retome pelo manager (§ Estados)"
fi
case "$TARGET" in
  antigravity)
    # Política: emitir SEMPRE (a chamada de modelo que gera o plano é tardia no loop do /plan).
    # Para emitir só na 1ª invocação, descomente a linha abaixo:
    # N=$(printf '%s' "$IN" | sed -n 's/.*"invocationNum"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p'); [ "${N:-0}" -gt 0 ] && exit 0
    printf '{"injectSteps":[{"ephemeralMessage":"DotAgents: protocolo da squad ativo (%s/commands/manager.md) — classifique, anuncie a persona e garanta o task.md antes de agir; vale DENTRO de /plan e comandos nativos (plano = personas produzindo o task.md). Nova demanda sem relação com o que esta sessão já tratou? Aplique manager § 🧹 (reset de contexto). Estado: %s."}]}\n' "$AR" "$TASK"
    ;;
  cursor)
    printf '{"additional_context":"[DotAgents] Protocolo da squad ativo — toda demanda é regida por %s/commands/manager.md. 1) Classifique, anuncie a persona e garanta o task.md ANTES de agir. 2) Vale DENTRO de modos nativos (plan/agent): planejar = personas produzindo o conteudo do task.md; ao sair do modo somente-leitura, materialize-o antes de editar codigo. 3) Nova demanda sem relacao com o que esta sessao ja tratou? Aplique manager § 🧹 (reset de contexto). 4) Estado: %s."}\n' "$AR" "$TASK"
    ;;
  *)
    printf '[DotAgents] Protocolo da squad ativo — esta demanda é regida por %s/commands/manager.md.\n' "$AR"
    printf '1) Classifique, anuncie a persona (📢) e garanta o task.md ANTES de agir.\n'
    printf '2) Vale DENTRO de comandos nativos (/plan, modo de planejamento): execute a intenção do comando ATRAVÉS da squad — planejar = personas produzindo o conteúdo do task.md; ao sair do plan mode, a primeira ação é materializá-lo.\n'
    printf '3) Nova demanda sem relação com o que esta sessão já tratou? Aplique manager § 🧹 (reset de contexto) antes de refinar.\n'
    printf '4) Estado: %s.\n' "$TASK"
    ;;
esac
exit 0
