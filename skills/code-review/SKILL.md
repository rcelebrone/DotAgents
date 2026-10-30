---
name: code-review
description: Revisão holística pré-commit (estilo PR Review). Valida o diff contra as 3 memórias vivas, a spec da task e Clean Code, em paralelo ao QA/Security (fan-out); a evidência de teste é exigida no join. Executada pelo Tech Lead; veredito escrito em review.md.
---

# Skill: Code Review (Gate Pré-Commit)

**Objetivo:** gate de qualidade pré-commit executado pelo **Tech Lead** no **fan-out de verificação**, em paralelo ao QA e ao Security (manager § 🔀). O veredito é **escrito em `docs/todo/<NNN-slug>/review.md`** (template canônico `memories/templates/review.md`) — relatório apenas no chat não conta.

## 0. Entrada e pré-condição do join
- **Portões determinísticos pré-review (Hard Gates):** antes de iniciar a leitura probabilística, execute `linter-enforcer` e `ast-validator`. Se houver falha de sintaxe, formatação ou resolução de símbolos/imports, **interrompa o review imediatamente** e devolva ao Developer com a saída do terminal (zero desperdício de tokens de LLM com revisão subjetiva).
- **Entrada do review:** Status `em-verificacao`, T00x concluídos, § Evidências preenchida e portões determinísticos verdes — **não** espera o qa-report.
- **Pré-condição do join** (checada depois, pelo TL, antes de `aprovada-para-entrega` — sem ela, proibido aprovar a entrega):
  - `qa-report.md` presente, com veredito APROVADO, `coverage-gate` atendido e **evidência real de execução** (saída de comandos colada).
  - Projeto sem suíte → justificativa escrita no qa-report com a verificação mínima viável executada.
  - Superfície sensível tocada → `security-review.md` presente, com Critical/High mitigados ou aceitos pelo procedimento único (manager § 🚧 Aceite de Risco).

## 1. Coleta de Contexto
- `docs/todo/<NNN-slug>/task.md` (spec, DoD, checklist, decisões, § Evidências do Developer).
- As 3 memórias: `memories/guidelines.md`, `memories/architecture.md`, `memories/business.md`.
- **Fragmentos ativados:** linhas `FRAGMENTO ATIVO:` de `{{AGENTS_ROOT}}/hooks/dotagents-verify.sh diff 2>&1` (skill `compound` § 5) — leitura obrigatória antes do veredito.

## 2. Diff Analysis
- Analisar as mudanças da branch/ciclo (`git diff`), mapeando os arquivos alterados vs § Arquivos Alterados da task.

## 2.1 Verificações Determinísticas (Verify-Cmd)
- Rode `{{AGENTS_ROOT}}/hooks/dotagents-verify.sh diff 2>&1` na raiz do escopo (lint + seleção + execução no snapshot — skill `compound` § 5) e cole a saída inteira (fragmentos ativos, tabela **comando + exit code**, ⚠️ e 🚨) em `review.md § Verificações Determinísticas`.
- **Verificador alterado** (diff ou atualização da squad que muda `hooks/dotagents-verify.sh`) → 🚨: execute a versão do merge-base fora do repositório e revise a mudança do script manualmente. Verificador sem versão no merge-base (instalação da squad nesta branch) → ⚠️; revise-o manualmente e registre em Ressalvas (skill `compound` § 5).
- **⚠️ entrada removida ou alterada neste diff:** confirme que a regra não foi enfraquecida (Verify-Cmd afrouxado, Escopo reduzido, entrada apagada); enfraquecimento sem justificativa registrada na task → CHANGES REQUESTED (Guidelines ❌).
- **⚠️ entrada desativada neste diff (SUPERSEDED):** confirme que existe a entrada substituta; sem ela, CHANGES REQUESTED (Guidelines ❌).
- **Exit 3 (🚨):** nenhum Verify-Cmd foi executado ou a execução falhou (gramática, symlink, merge-base, git, ferramenta ausente, erro do comando, timeout) — cole as linhas 🚨 em Ressalvas e decida o veredito como CHANGES REQUESTED (memória a corrigir) ou bloqueio de ambiente, nunca como "nenhum Verify-Cmd aplicável".
- **Efeito no veredito:** qualquer linha da tabela com exit 1 (violação) → dimensão Guidelines (ou Arquitetura, quando a entrada é `ARQUITETURA`) ❌ e veredito 🔁 CHANGES REQUESTED, com a saída do comando colada.

## 3. Checklist de Validação Cruzada
- **Spec (task ↔ código):** todos os itens implementados? Algum CA do DoD sem cobertura? Scope creep?
- **Guidelines:** naming, estrutura, Clean Code e entradas `PADRAO_SEMANTICO` respeitados? (Entradas `PADRAO_VERIFICAVEL` já foram decididas pelo exit code no § 2.1 — não as reavalie por leitura.)
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
