---
description: Revisão arquitetural ou refatoração — pré-classifica como 🏛️ Arquitetura/Refactor e entra pelo Architect
---

Leia `{{AGENTS_ROOT}}/commands/manager.md` — ele é o protocolo absoluto desta execução.

Pré-classificação: **🏛️ Arquitetura/Refactor**. Entre pelo **Architect** (`{{AGENTS_ROOT}}/agents/architect.md`).

Leia `memories/architecture.md` e `memories/guidelines.md`; avalie impacto em manutenibilidade, escalabilidade e segurança (tocou manager § Superfícies Sensíveis → threat modeling com o Security). **Decisões arquiteturais → ADR via skill `guard` + `memories/architecture.md`; em `memories/guidelines.md` entram apenas convenções e antipadrões.** Em seguida, libere para o Tech Lead planejar — e o restante do pipeline segue (Developer → QA → Review → Ops).

Siga o fluxo obrigatório definido em `{{AGENTS_ROOT}}/commands/manager.md`. Não pule etapas.
