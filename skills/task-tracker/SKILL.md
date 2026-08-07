---
name: task-tracker
description: Escaneia docs/todo/ reportando o Status de cada task e arquiva em docs/done/ somente as entregues. Use para "verificar tasks", "o que está pendente" ou "arquivar concluídas".
---

# Skill: Task Tracker

## 1. Scan
Varrer `docs/todo/`, lendo a linha `**Status:**` do `task.md` de cada subdiretório (a **palavra** é normativa — ver manager § 📌 Estados da Task).

## 2. Relatório
Sumário por status (em-refinamento → entregue, pausada, bloqueada), com prioridade e tipo. Diretório sem linha `**Status:**` (formato legado) → listar como **legado** — apenas reportar, NUNCA arquivar automaticamente.

## 3. Trava de Arquivamento
Arquivar SOMENTE quando TODAS as condições valem:
- `**Status:**` contém `entregue` no task.md;
- `review.md` presente com veredito APPROVED;
- `qa-report.md` presente com veredito aprovado;
- `Tipo: hotfix|rollback` → `**Retro:**` diferente de `pendente`.
Checkboxes marcados NÃO bastam — o Status e os artefatos de gate são a verdade.

## 4. Arquivamento
Mover o **diretório inteiro** `docs/todo/<NNN-slug>/` → `docs/done/<NNN-slug>/` (task.md + qa-report.md + review.md + security-review.md + demais artefatos, intactos).

## 5. Confirmação
Informar o que foi arquivado e o que permanece (com status, e o motivo da retenção quando houver).

## Restrições
- Esta skill NÃO altera Status nem marca checkboxes — só reporta e arquiva.
- NNN de task arquivada nunca é reutilizado (regra de alocação do manager).
