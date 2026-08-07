---
name: code-review
description: Revisão holística pré-commit (estilo PR Review). Valida o diff contra as 3 memórias vivas, a spec da task e Clean Code, com pré-condição de evidência de teste. Executada pelo Tech Lead; veredito escrito em review.md.
---

# Skill: Code Review (Gate Pré-Commit)

**Objetivo:** gate de qualidade pré-commit executado pelo **Tech Lead** após a aprovação do QA (e do Security, quando acionado). O veredito é **escrito em `docs/todo/<NNN-slug>/review.md`** (template canônico `memories/templates/review.md`) — relatório apenas no chat não conta.

## 0. Pré-condição (obrigatória — sem ela, proibido aprovar)
- `qa-report.md` presente, com veredito APROVADO e **evidência real de execução** (saída de comandos colada).
- Projeto sem suíte → justificativa escrita no qa-report com a verificação mínima viável executada.
- Superfície sensível tocada → `security-review.md` presente, com Critical/High mitigados ou aceitos pelo procedimento único (manager § 🚧 Aceite de Risco).

## 1. Coleta de Contexto
- `docs/todo/<NNN-slug>/task.md` (spec, DoD, checklist, decisões) e `qa-report.md`.
- As 3 memórias: `memories/guidelines.md`, `memories/architecture.md`, `memories/business.md`.
- `memories/implementations/INDEX.md` → fragmentos do domínio tocado, se houver.

## 2. Diff Analysis
- Analisar as mudanças da branch/ciclo (`git diff`), mapeando os arquivos alterados vs § Arquivos Alterados da task.

## 3. Checklist de Validação Cruzada
- **Spec (task ↔ código):** todos os itens implementados? Algum CA do DoD sem cobertura? Scope creep?
- **Guidelines:** naming, estrutura, Clean Code, restrições e antipadrões registrados respeitados?
- **Arquitetura:** decisões/ADRs respeitados (apoio: skill `guard` § Conformidade), NFRs considerados, dependências novas alinhadas?
- **Negócio:** regras conforme `business.md`, glossário de domínio respeitado, permissões corretas?
- **Higiene:** código morto, imports não usados, funções gigantes (complexidade ciclomática), duplicação, código de debug, segredos.

## 4. Veredito (escrito em review.md)
Preencher o template canônico: pré-condição, tabela de conformidade, veredito **✅ APPROVED | 🔁 CHANGES REQUESTED** e ressalvas/aceites ativos.
- **APPROVED** → TL define Status `aprovada-para-entrega`, marca os checkboxes de Gate e delega ao Ops.
- **CHANGES REQUESTED** → devolver ao Developer com o review.md (re-passar pelo QA somente se as mudanças forem substanciais).

## 5. Loop Limitado
Máx **3 iterações** TL⇄Developer (campo `Iteração: N/3` no review.md). Na 3ª reprovação: escalar ao usuário via PO — opções do manager § Loops Limitados.

## Restrições
- Não duplicar validação funcional (QA) nem auditoria de segurança (Security) — o review é de **conformidade**.
- Review sem review.md gravado não aconteceu (regra universal dos gates).
- Manter o tom configurado em `memories/guidelines.md` (§ Personalidade e Tom de Voz).
