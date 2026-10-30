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
- **Fragmentos ativados:** linhas `FRAGMENTO ATIVO:` da saída do verificador (§ 2.1; skill `compound` § 5) — leitura obrigatória antes do veredito.

## 2. Diff Analysis
- Analisar as mudanças da branch/ciclo (`git diff`), mapeando os arquivos alterados vs § Arquivos Alterados da task.

## 2.1 Verificações Determinísticas (Verify-Cmd)
- **Modo de execução (dois modos):**
  - **Gate pré-commit da squad (padrão):** o review roda sobre o trabalho **não commitado** do Developer (só o Ops commita) — rode o verificador **no worktree do Developer**, sem `--review`. Merge-base igual a `HEAD` é o caso normal ali (⚠️ informativo).
  - **Revisão de branch ou PR já commitados** (fora do fluxo pré-commit): `--review`, num worktree novo (`git worktree add <dir> <branch>`) ou num clone do remoto **canônico** — nunca no fork do autor (PR de fork: `git fetch <canônico> pull/<N>/head` num clone do canônico). Um `.gitattributes` alterado entre iterações não regrava arquivos cujo blob não mudou (checkout velho); clone de um checkout local aponta `origin/HEAD` para a branch da task. O `--review` recusa (🚨) merge-base igual a `HEAD` e qualquer mudança local, inclusive arquivo novo não rastreado.
- **Checagem externa do verificador, antes de rodá-lo:** rode o comando da skill `compound` § 5 ("checagem externa do verificador"; repositório sem remoto: a variante "sem remoto") e só execute o verificador do repositório se ele imprimir `verificador conforme ao merge-base`, porque a autoverificação interna é feita pelo próprio script e um verificador reescrito pode pulá-la. Sem essa linha: verificador diferente → rode a versão do merge-base fora do repositório; branch remota inexistente num repositório com remoto → ambiente (`git fetch`) e rode de novo; **instalação da squad nesta branch** (sem versão no merge-base) → revise o script manualmente antes de rodá-lo e registre a revisão em Ressalvas.
- Rode, na raiz do escopo, `DOTAGENTS_BASE_BRANCH=origin/<branch padrão> {{AGENTS_ROOT}}/hooks/dotagents-verify.sh diff 2>&1` (gate pré-commit) ou `… diff --review 2>&1` (branch commitada) — o mesmo ref da checagem externa; sem remoto, `DOTAGENTS_BASE_BRANCH=<branch padrão>`, o ref da variante sem remoto (lint + seleção + execução no snapshot — skill `compound` § 5) — e cole a saída inteira (fragmentos ativos, tabela **comando + exit code**, ⚠️ e 🚨) em `review.md § Verificações Determinísticas`.
- **Verificador alterado** (diff ou atualização da squad que muda `hooks/dotagents-verify.sh`) → 🚨: execute a versão do merge-base fora do repositório e revise a mudança do script manualmente. Verificador sem versão no merge-base (instalação da squad nesta branch) → ⚠️; revise-o manualmente e registre em Ressalvas (skill `compound` § 5).
- **⚠️ entrada removida ou alterada neste diff:** confirme que a regra não foi enfraquecida (Verify-Cmd afrouxado, Escopo reduzido, entrada apagada); enfraquecimento sem justificativa registrada na task → CHANGES REQUESTED (Guidelines ❌).
- **⚠️ entrada desativada neste diff (SUPERSEDED):** confirme que existe a entrada substituta; sem ela, CHANGES REQUESTED (Guidelines ❌).
- **Exit 3 (🚨)** — cole as linhas 🚨 em Ressalvas; nunca registre como "nenhum Verify-Cmd aplicável". Destino por causa:
  - **memória ou diff** (lint reprovado, gramática, CRLF, byte NUL, INDEX, symlink ou nome inválido em `memories/`; `working-tree-encoding` em `memories/` ou em arquivo verificado — o diff ou o `.gitattributes` do repositório transcodifica o que o verificador lê; arquivo verificado que começa com BOM UTF-16/32 — converta-o para UTF-8 ou tire-o dos paths da entrada; no gate pré-commit, "está na working tree com NUL ou BOM" num arquivo **do diff** — a conversão é do trabalho em revisão: devolva pedindo UTF-8 sem BOM, sem restaurar do git) ou **erro do comando** de uma entrada (regex ou path inválido) → 🔁 CHANGES REQUESTED (Guidelines ❌), com a correção (memória em UTF-8 LF, atributo removido) na devolução;
  - **verificador alterado** → rode a versão do merge-base fora do repositório; o veredito segue a saída dela + a revisão manual do script;
  - **ambiente** — **qualquer outro 🚨** (merge-base não resolvido, git falhou, ferramenta ausente, timeout, `memories/` ausente por rodar fora da raiz, `mktemp` ou `DOTAGENTS_VERIFY_TIMEOUT` inválido, nome de arquivo com quebra de linha ou controle no repositório, **checkout velho** — arquivo que "difere do blob do índice sem mudança registrada pelo git", ou "está na working tree com NUL ou BOM" num arquivo **fora** do diff) → não emita veredito: corrija o ambiente (instale a ferramenta, rode na raiz do escopo, defina `DOTAGENTS_BASE_BRANCH`, ajuste `DOTAGENTS_VERIFY_TIMEOUT`, renomeie o arquivo; checkout velho no **gate pré-commit**: corrija **no worktree do Developer** — salve uma cópia do arquivo fora do repositório, `rm` + `git checkout -- <arquivo>` ou `git update-index --no-assume-unchanged --no-skip-worktree -- <arquivo>`, nunca troque de worktree, porque o trabalho não commitado só existe nele; na **revisão de branch commitada**: worktree novo (`git worktree add`) ou clone do remoto canônico) e rode de novo — o review só fecha sobre uma saída sem 🚨 de ambiente.
- **⚠️ diff vazio** ("nada foi verificado") com § Arquivos Alterados preenchido no task.md → não emita veredito: o verificador rodou fora do worktree do Developer; rode-o lá. 🚨 do `--review` no gate pré-commit (merge-base igual a `HEAD` ou worktree sujo) → modo errado: rode `diff` sem `--review` no worktree do Developer.
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
