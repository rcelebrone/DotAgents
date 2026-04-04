---
name: adr-automator
description: |
  Formaliza e regista mudanças estruturais ou de biblioteca significativas na arquitetura do sistema, garantindo que o "porquê" (a memória arquitetural) destas decisões seja preservado.
---

# Architectural Decision Record (ADR) Automator

## Gatilhos de Ativação (Triggers)
- Mudança de bibliotecas conectadas à infraestrutura core (ex: Mudar o framework de log, framework de DB).
- Refactoring complexo e alteração visível do padrão de projeto (ex: mudar de Repositories diretos para MediatR / CQRS).
- Introdução de novos serviços do qual o sistema ganha forte dependência.

## Workflow
1. Criar novo arquivo dentro de `docs/adr/`, com a estrutura sequencial `NNN-titulo.md`.
2. Seguir a formatação oficial de ADR (Abaixo).
3. Confirmar Status (`Proposed`) até validação humana alterar para `Accepted`.

## Template Base

```markdown
# ADR [Número]: [Título da Decisão]

**Data:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated
**Contexto de Decisão:** [Nome do Agente/Usuário]

### Contexto e Problema
[Descrever o motivo e contexto para o qual uma ação foi necessária]

### Decisão Técnica Sugerida
[Detalhar a solução escolhida e como será aplicada nas camadas]

### Consequências
- **Positivas:** [Ganhos de longo prazo ou performance]
- **Negativas:** [Dívida técnica acumulada ou limite adicionado]
```
