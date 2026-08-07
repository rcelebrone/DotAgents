---
name: delivery
description: Fecha o ciclo de entrega local — build check, bump semântico, changelog e commit convencional. Deploy remoto somente sob a condição dupla do Ops. Use para "finalizar tarefa", "fazer release" ou "publicar versão".
---

# Skill: Delivery (Ciclo de Entrega)

Executada pelo **Ops**, somente após o Gate do Ops (checklist pré-entrega + [S/N] afirmativo — ver `{{AGENTS_ROOT}}/agents/ops.md`).

## 1. Build Check
Executar o comando de build da stack (registrado em `memories/architecture.md` no bootstrap: `npm run build`, `go build`, `mvn package`, etc.) **agora**, colando a saída em task.md § Evidências. Build quebrado → parar e devolver ao fluxo (sem commit).

## 2. Versionamento Semântico
Bump no manifesto principal (`package.json`, `version.go`, `VERSION`, etc.):
- `feat` → **minor** · `fix`/`chore` → **patch** · **breaking change** → **major**, somente com confirmação explícita do usuário.

## 3. Changelog
Atualizar `CHANGELOG.md` (ou equivalente) com a entrega do ciclo, referenciando a Task NNN.

## 4. Commit Local (Conventional Commits)
- Formato: `tipo(escopo): descrição` — tipos: `feat|fix|refactor|chore|docs|test|perf`.
- Corpo referencia a task: `Task NNN`.
- Tag anotada `vX.Y.Z` opcional, conforme convenção registrada em `memories/architecture.md`.

## 5. Deploy Remoto (fronteira dura)
- **Default: NÃO existe.** Push/deploy remoto SOMENTE com (a) procedimento registrado em `memories/architecture.md § Deploy` **e** (b) segunda confirmação explícita do usuário nomeando o alvo (condição dupla do Ops — o opt-out não a dispensa).
- Sem a condição dupla, encerre no ciclo local e informe o usuário.

## 6. Encerramento
- Resultado (build + versão + commit) registrado em task.md § Evidências.
- Remova `docs/todo/.dotagents-bypass` se existir.
- Handoff: **PO (Validação Final)** — nunca direto ao compound.
