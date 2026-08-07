---
description: Deploy, release ou gestão de dependências — pré-classifica como 🚀 e entra pelo Ops com o gate completo
---

Leia `{{AGENTS_ROOT}}/commands/manager.md` — ele é o protocolo absoluto desta execução.

Pré-classificação: **🚀 Deploy/Release/Deps**. Entre pelo **Ops** (`{{AGENTS_ROOT}}/agents/ops.md`).

Gate completo do Ops (manager § 🚧):
1. Verifique que as tasks do ciclo estão `aprovada-para-entrega` (review.md APPROVED). Task fora desse estado → **devolva ao estágio devido** — este comando não pula gates.
2. Checklist Pré-Entrega do Ops (build executado agora, migrations destacadas) e confirmação **[S/N]** citando a task.
3. Entrega local via `{{AGENTS_ROOT}}/skills/delivery/SKILL.md` (changelog + bump + commit convencional).
4. **Deploy remoto somente sob a condição dupla:** procedimento em `memories/architecture.md § Deploy` **E** segunda confirmação do usuário nomeando o alvo. Sem isso, encerre no ciclo local.

Auditoria de dependências/infra → `{{AGENTS_ROOT}}/skills/infrastructure/SKILL.md` (CVEs → Security classifica).

Siga o fluxo obrigatório definido em `{{AGENTS_ROOT}}/commands/manager.md`. Não pule etapas.
