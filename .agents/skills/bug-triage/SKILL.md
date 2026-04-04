---
name: bug-triage
description: |
  Transforma logs de erro brutos e stack traces em diagnósticos detalhados e gera planos de ação para a skill de start-feature.
---

# Bug Triage & Root Cause Analysis (RCA)

## Gatilhos de Ativação (Triggers)
- Quando o usuário enviar um erro de build, stacktrace de crash, ou problemas de execução isolados em uma seção, ative este fluxo.

## Workflow
1. Receber e isolar o Log / Stack Trace principal do usuário.
2. Analisar o repositório base para tentar localizar o arquivo exato e linha provável do erro (dada a indicação principal).
3. Criar uma task em `.agents/docs/tasks/` com o diagnóstico primário, hipóteses da causa (Root Cause Analysis - RCA), e passos exatos sugeridos para correção.
4. Acionar internamente a skill `start-feature` (tipo `fix`) para inicializar o fluxo de correção se o usuário concordar em seguir.
