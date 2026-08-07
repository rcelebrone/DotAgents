---
description: Reportar e corrigir um bug — pré-classifica como 🐛 Bug e entra no pipeline pelo Tech Lead (triage)
---

Leia `{{AGENTS_ROOT}}/commands/manager.md` — ele é o protocolo absoluto desta execução.

Pré-classificação: **🐛 Bug** (sinais de urgência de produção → reclassifique como 🚑 Hotfix, manager § 🔀 Rotas). Entre pelo **Tech Lead** (`{{AGENTS_ROOT}}/agents/techlead.md`).

O TL executa `{{AGENTS_ROOT}}/skills/triage/SKILL.md` — Reprodução + RCA escritos em `docs/todo/<NNN-slug>/task.md` (`Tipo: bug`, criado do template `memories/templates/task.md`). Bug que muda regra de negócio → PO valida antes do planejamento. Depois, o fluxo completo: **Developer** → **QA Specialist** (qa-report.md) → **Security** se tocar Superfície Sensível → **Review do Tech Lead** (review.md) → **Ops**.

Siga o fluxo obrigatório definido em `{{AGENTS_ROOT}}/commands/manager.md`. Não pule etapas.
