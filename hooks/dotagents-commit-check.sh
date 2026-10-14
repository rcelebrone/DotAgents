#!/bin/sh
# DotAgents commit checker: valida deterministamente o formato Conventional Commits via RegEx.
# Pode ser invocado como git hook (commit-msg $1), via stdin (cat msg | dotagents-commit-check.sh),
# ou passando a mensagem como argumento string.
# Retorna exit 0 em caso de aprovação ou exit 1 com motivo da rejeição.

set -e

MSG=""
if [ -n "$1" ]; then
  if [ -f "$1" ]; then
    MSG=$(cat "$1")
  else
    MSG="$1"
  fi
else
  MSG=$(cat 2>/dev/null || echo "")
fi

if [ -z "$MSG" ]; then
  echo "❌ [DotAgents Commit Checker] Mensagem de commit vazia." >&2
  exit 1
fi

# Extrai primeira linha (cabeçalho)
FIRST_LINE=$(printf '%s\n' "$MSG" | head -n 1)

# RegEx do cabeçalho (Conventional Commits v1.0.0):
# - Tipos autorizados: feat, fix, refactor, chore, docs, test, perf, style, ci, build
# - Escopo opcional: (escopo-kebab-ou-snake)
# - Marcador breaking opcional: !
# - Separador: ': '
# - Descrição: não vazia, sem ponto final, máximo 100 caracteres
REGEX_HEADER='^(feat|fix|refactor|chore|docs|test|perf|style|ci|build)(\([a-z0-9._-]+\))?!?: [^A-Z[:punct:]].{1,99}[^.]$'

if ! printf '%s' "$FIRST_LINE" | grep -Eq "$REGEX_HEADER"; then
  echo "❌ [DotAgents Commit Checker] Cabeçalho de commit inválido!" >&2
  echo "   Recebido: '$FIRST_LINE'" >&2
  echo "   Padrão esperado: tipo(escopo)?: descrição no imperativo sem ponto final (máx 100 chars)" >&2
  echo "   Tipos válidos: feat | fix | refactor | chore | docs | test | perf | style | ci | build" >&2
  echo "   Exemplo: feat(auth): implementar middleware de verificacao de sessao" >&2
  exit 1
fi

# Valida se há corpo e exige separação por linha em branco
TOTAL_LINES=$(printf '%s\n' "$MSG" | wc -l)
if [ "$TOTAL_LINES" -gt 1 ]; then
  SECOND_LINE=$(printf '%s\n' "$MSG" | sed -n '2p')
  if [ -n "$SECOND_LINE" ]; then
    echo "❌ [DotAgents Commit Checker] A segunda linha DEVE ser uma linha em branco separando o título do corpo." >&2
    exit 1
  fi

  # Se houver corpo/rodapé, valida presença de referência à Task
  if ! printf '%s\n' "$MSG" | grep -Eq '(Task [0-9]+|Task [0-9]+-[a-z0-9-]+|Closes #[0-9]+|Fixes #[0-9]+|BREAKING CHANGE:)'; then
    echo "⚠️ [DotAgents Commit Checker] Recomendação: inclua referência à task no rodapé (ex.: 'Task NNN' ou 'Closes #NNN')." >&2
  fi
fi

echo "✅ [DotAgents Commit Checker] Mensagem conforme o padrão Conventional Commits."
exit 0
