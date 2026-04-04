---
name: start-feature
description: |
  Esta skill é responsável por orquestrar o início de qualquer novo trabalho de desenvolvimento. Ela garante que o agente nunca trabalhe na branch principal, siga padrões de nomenclatura rigorosos e decomponha requisitos de alto nível em unidades de trabalho documentadas.
---

# Feature Initialization & Task Orchestrator

## Gatilhos de Ativação (Triggers)
A skill deve ser disparada automaticamente quando o usuário solicitar solicitações iniciais, como:
- "Implementa a funcionalidade [X]"
- "Crie um novo módulo para [Y]"
- "Resolve o bug [Z]"
- "Refatora o componente [W]"

## Protocolo de Branching
O agente deve classificar a intenção e criar uma branch utilizando o seguinte padrão: `<tipo>/<nome-da-feature-kebab-case>`.
Convenções de Tipo:
- `feat`: Para novas funcionalidades.
- `fix`: Para correções de bugs.
- `refactor`: Para melhorias de código.
- `chore`: Para tarefas de manutenção.

## Orquestração de Tarefas (.agents/docs/tasks/)
Sempre que a skill for ativada, o agente deve:
1. Criar a branch correspondente.
2. Identificar as sub-tarefas da funcionalidade.
3. Criar na pasta `.agents/docs/tasks/` um arquivo Markdown para cada task identificada, seguindo a nomenclatura `001-nome-da-task.md`.
