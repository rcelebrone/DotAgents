---
name: triage
description: Triagem e causa raiz (RCA) de bugs. Use quando o usuário reportar "erro", "bug" ou "falha" para reproduzir, classificar e isolar o problema antes de qualquer correção.
---

# Skill: Triage (Reprodução + RCA)

Executada pelo **Tech Lead** (porta de entrada de bugs) ou pelo **QA** (falhas encontradas em auditoria). Alimenta as seções `## Reprodução` e `## RCA` do `docs/todo/<NNN-slug>/task.md` (`Tipo: bug` ou `hotfix`).

## 1. Protocolo de Reprodução (antes de qualquer hipótese)
Colete e registre em `## Reprodução`:
- **Contexto:** commit/versão, ambiente (SO, runtime, browser), configuração relevante.
- **Passos numerados** para reproduzir.
- **Esperado × Obtido** (comportamento correto vs observado).
- **Evidência:** stack trace, logs, screenshot ou saída de comando.

**Reproduza localmente ANTES de hipotetizar.** Não reproduzível → solicite os dados faltantes ao usuário — nunca adivinhe a causa. Intermitente → registre frequência e condições observadas.

## 2. Classificação de Severidade
Use a escala canônica Sev1–4 definida em `{{AGENTS_ROOT}}/agents/qa-specialist.md` (§ Escala de Severidade). Sev1 em produção → considere a rota 🚑 Hotfix do manager (§ 🔀 Rotas).

## 3. RCA (Root Cause Analysis)
Preencha `## RCA` no task.md:
- **Causa raiz** (a falha de origem, não o sintoma).
- **Evidência** que sustenta a conclusão (arquivo:linha, teste que demonstra).
- **Hipóteses descartadas** (e por quê — evita retrabalho nos loops).
- **Arquivos prováveis** para a correção (arquivo:linha).

## 4. Ação
- Task ainda não existe → crie via `{{AGENTS_ROOT}}/skills/feature-flow/SKILL.md` (`Tipo: bug`, branch `fix/NNN-slug`) e preencha Reprodução + RCA.
- Bug que revela mudança de regra de negócio → PO valida antes do planejamento.
- Entregue ao Tech Lead para o planejamento da correção (fluxo normal do manager).

## Restrições
- Triage NÃO corrige código — diagnostica e prepara a task.
- RCA sem reprodução (ou sem justificativa escrita de por que não foi possível reproduzir) é violação.
