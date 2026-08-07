---
name: feature-flow
description: Cria o diretório canônico da task (docs/todo/NNN-slug/), a branch e o scaffolding inicial. Use para "criar feature", "iniciar tarefa" ou "abrir task".
---

# Skill: Feature Flow (Abertura de Task)

Fluxo único de criação — TODA task nasce assim (feature, bug, refactor, docs, hotfix, rollback):

## 1. Alocação de NNN
Liste `docs/todo/` **e** `docs/done/`; NNN = maior prefixo numérico + 1 (3 dígitos, zero-padded). Diretório resultante já existe → incremente até o primeiro livre. NNN nunca é reutilizado.

## 2. Criação do Artefato
Crie `docs/todo/<NNN-slug>/task.md` a partir do template canônico `memories/templates/task.md`, preenchendo `Tipo`, `Status: em-refinamento`, `Prioridade`, `Branch` e a primeira linha do Log.
- Invocada pelo **PO** (feature/docs): PO preenche Demanda, User Stories, Gate de Completude, NFRs e DoD no próprio task.md.
- Invocada pelo **TL** (bug/hotfix, via triage): TL preenche Reprodução e RCA.

## 3. Branch
Criar `<tipo>/NNN-slug` (tipos: `feat`, `fix`, `refactor`, `docs`, `hotfix`, `rollback`). O NNN na branch elimina colisões — ainda assim, verifique se a branch já existe antes de criar.

## 4. Scaffolding (opcional, pós-planejamento)
Gerar boilerplate (entities, controllers, services) conforme o padrão registrado em `memories/architecture.md` — somente após o TL definir a checklist (`Status: planejada`).

## Restrições
- NENHUM outro layout é válido: sem `docs/features/`, sem arquivos soltos em `docs/todo/`, sem `tasks.md` (plural).
- Esta skill não implementa código de produção.
