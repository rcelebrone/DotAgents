Skill: Architectural Decision Record (ADR) Automator

1. Descrição

Formaliza mudanças significativas na arquitetura do sistema, garantindo que o "porquê" das decisões seja preservado.

2. Trigger

Mudança de bibliotecas core.

Alteração de padrões de projeto (ex: mudar de Repositories para MediatR).

Introdução de novas tecnologias ou serviços externos.

3. Workflow

Criar arquivo em docs/adr/NNN-titulo.md.

Seguir o status: Proposed -> Accepted (após validação humana).

4. Template ADR

# ADR [Número]: [Título da Decisão]

**Data:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated
**Participantes:** [Nome do Agente/Usuário]

### Contexto e Problema
[Descrever o cenário que motivou a mudança]

### Decisão Proposta
[Detalhar a solução técnica escolhida]

### Consequências
- **Positivas:** [Benefícios]
- **Negativas:** [Dívida técnica ou limitações]
