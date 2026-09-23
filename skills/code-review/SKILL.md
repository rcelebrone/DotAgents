---
name: code-review
description: Revisão holística pré-commit (estilo PR Review). Valida o diff contra as 3 memórias vivas, a spec da task e Clean Code, em paralelo ao QA/Security (fan-out); a evidência de teste é exigida no join. Executada pelo Tech Lead; veredito escrito em review.md.
---

# Skill: Code Review (Gate Pré-Commit)

**Objetivo:** gate de qualidade pré-commit executado pelo **Tech Lead** no **fan-out de verificação**, em paralelo ao QA e ao Security (manager § 🔀). O veredito é **escrito em `docs/todo/<NNN-slug>/review.md`** (template canônico `memories/templates/review.md`) — relatório apenas no chat não conta.

## 0. Entrada e pré-condição do join
- **Entrada do review:** Status `em-verificacao`, T00x concluídos e § Evidências preenchida — **não** espera o qa-report.
- **Pré-condição do join** (checada depois, pelo TL, antes de `aprovada-para-entrega` — sem ela, proibido aprovar a entrega):
  - `qa-report.md` presente, com veredito APROVADO e **evidência real de execução** (saída de comandos colada).
  - Projeto sem suíte → justificativa escrita no qa-report com a verificação mínima viável executada.
  - Superfície sensível tocada → `security-review.md` presente, com Critical/High mitigados ou aceitos pelo procedimento único (manager § 🚧 Aceite de Risco).

## 1. Coleta de Contexto
- `docs/todo/<NNN-slug>/task.md` (spec, DoD, checklist, decisões, § Evidências do Developer).
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
Preencher o template canônico: tabela de conformidade, veredito **✅ APPROVED | 🔁 CHANGES REQUESTED** e ressalvas/aceites ativos. Como gate paralelo, **não altere o task.md**.
- **Join (TL, com todos os artefatos do fan-out):** preencher § Join do review.md. Tudo ✅ → Status `aprovada-para-entrega`, checkboxes de Gate e delegação ao Ops. Qualquer ❌ → devolução consolidada ao Developer; na volta, re-despachar em paralelo só os gates cujo escopo o delta tocou (manager § 🔀).

## 5. Loop Limitado
Máx **3 iterações** TL⇄Developer (campo `Iteração: N/3` no review.md). Na 3ª reprovação: escalar ao usuário via PO — opções do manager § Loops Limitados.

## Restrições
- Não duplicar validação funcional (QA) nem auditoria de segurança (Security) — o review é de **conformidade**.
- Review sem review.md gravado não aconteceu (regra universal dos gates).
- Manter o tom configurado em `memories/guidelines.md` (§ Personalidade e Tom de Voz).
