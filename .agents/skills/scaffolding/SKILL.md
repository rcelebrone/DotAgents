---
name: scaffolding
description: |
  Gera boilerplate e componentes básicos padronizados de acordo com as especificações e restrições arquiteturais da codebase atual.
---

# Onboarding & Scaffolding

## Gatilhos de Ativação (Triggers)
- Ao receber comandos como "Crie uma entidade [Nome]" ou "Estruture os controllers para [Modulo]".
- Durante tarefas onde criar arquivos em massa em várias camadas seja requerido antes de codificar a lógica real.

## Templates Abstratos
 *(Observação: Isto é parametrizável pelo `project-bootstrap` mas por base, cria as camadas de acordo com a stack dominante):*
- Se C#: Cria Entity, Repository Interfaces, DI Mappings, Unit Test File, ValueObject base.
- Se Dart/Flutter: Cria Entity, DataModel, Repository, State Management Class (e.g. Cubit), Widget/Screen básica.
- Se Node/JS: Cria Rota, Controller, Service Layer, Schema, Integration test boilerplate.

## Workflow
1. Analise o design system ou padrão base (`.agents/architecture.md` e codebase root) antes de criar pastas fora da recomendação comum.
2. Estruture toda a sequência de pastas.
3. Inicialize os `.cs` / `.dart` / `.ts` correspondentes com imports e definições vazias porém testáveis para que a compilação passe já no primeiro passo.
