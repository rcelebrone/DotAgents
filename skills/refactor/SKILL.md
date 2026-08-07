---
name: refactor
description: Reestruturação segura de código sem alterar o comportamento externo, para reduzir dívida técnica. Acionada pelo Architect ou Tech Lead.
---

# Skill: Safe Refactoring

## Pré-requisitos
- O código alvo DEVE ter cobertura de testes ou comportamento validável ANTES da refatoração (sem rede de proteção → primeiro abrir task de testes, depois refatorar).
- Ler `memories/guidelines.md` e `memories/architecture.md`.

## Passos
1. **Entendimento da Base:** avalie o alvo e liste as responsabilidades que ele fere (SRP) e os acoplamentos indevidos.
2. **Plano de Corte:** crie a task via `{{AGENTS_ROOT}}/skills/feature-flow/SKILL.md` (`Tipo: refactor`, branch `refactor/NNN-slug`) com micro-passos na checklist (extrair função, mover componente, unificar interface) — cada micro-passo com verificação própria.
3. **Execução:** o fluxo normal do manager assume (TL planeja → Developer executa preservando comportamento → QA re-executa a suíte → review).
4. **Critério de aceite fixo:** suíte verde antes E depois, sem mudança observável de comportamento externo.

## Restrições
- Refatoração NUNCA mistura mudança de comportamento (isso é feature/bug — task separada).
- Big-bang é proibido: micro-passos com verificação própria.
