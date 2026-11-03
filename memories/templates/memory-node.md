---
id: <dominio>-<assunto>
type: business | architecture | guideline
domain: <dominio-principal>
tags: [<tag1>, <tag2>]
summary: "<Resumo de 1 linha explicando exatamente o que este nó governa para que a IA decida se precisa ler o corpo>"
when_to_read: "<Gatilho claro: quando o agente deve ler este arquivo completo (ex.: ao tocar no componente X ou rota Y)>"
connections:
  - target: <id-de-outro-no>
    relation: "<ex.: valida-com | depende-de | compartilha-estado | restringe | aciona>"
    reason: "<Por que a IA que lê este arquivo pode precisar consultar o outro nó conectado>"
harness:
  - "<caminho/do/arquivo-de-config-ou-regra-deterministica>"
updated_at: AAAA-MM-DD
tasks: [NNN]
---

# <Título do Nó de Memória>

### [AAAA-MM-DD][Task NNN] <Título curto do aprendizado>
- **Aprendizado / Regra:** <o que aprendemos em 1–3 linhas>
- **Fonte:** [Feedback do Usuário | Decisão de QA/Review | Melhoria Aprovada | Consolidação Autônoma]
- **Harness (Guardrail Determinístico):** `<regra/config/script criado>` (validado via `<comando>`)
- **Origem:** `docs/done/NNN-slug/`
