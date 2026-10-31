---
name: compound
description: Persistência de aprendizados nas memórias vivas ao final de cada ciclo. Use para "atualizar memória", "guardar aprendizados" ou "sincronizar contexto do projeto". Executada pelo Tech Lead após o PO definir Status entregue.
---

# Skill: Compound (Memória Viva)

Executada pelo **Tech Lead** quando a task atinge Status `entregue` (pós-commit do Ops). Consolida o que o ciclo ensinou nas três memórias + fragmentos, convertendo cada aprendizado em entrada **tipada, com escopo de arquivos e, quando verificável, com asserção executável**.

**Ferramenta determinística:** `{{AGENTS_ROOT}}/hooks/dotagents-verify.sh`, rodado na raiz do escopo DotAgents (diretório com `memories/`) ou na raiz do repositório, é a fonte única da gramática, da listagem de entradas, da ativação por glob, da execução dos Verify-Cmd e dos arquivos do diff. Nenhum agente monta comando com texto lido das memórias ou com nomes de arquivo do diff — só chama o script.

| Modo | Uso |
|---|---|
| `lint` | valida memórias e INDEX (nada é executado) |
| `list` | entradas ativas (não-SUPERSEDED): arquivo, título, Tipo, Escopo, Regra, Verify-Cmd, Origem |
| `fragments [path...]` | fragmentos ativos para os paths dados (sem paths: arquivos do diff) |
| `diff` | review/self-review: fragmentos ativos + tabela dos Verify-Cmd aplicáveis ao diff |
| `run "<título>"` | baseline de uma entrada (entrada `N/A`: nada a executar, exit 0) |
| `probe "<título>" <arquivo>` | contraprova: a entrada detecta a violação contida em `<arquivo>`? (`N/A` e forma Estrutural: não se aplica, exit 0) |
| `base` | commit merge-base entre `HEAD` e a branch padrão |
| `paths [-z]` | arquivos regulares existentes tocados pelo diff, sem symlink e sem diretório-pai symlink (usado por `ast-validator` e `state-checkpoint`) |
| `deps [-z]` · `deps-revert` | manifestos e lockfiles do diff, inclusive deletados · revertê-los ao merge-base, recusando (🚨) manifesto sob diretório que virou symlink (usados por `dependency-lock`) |

- **Exit:** `0` conforme · `1` violação (ou contraprova não detecta) · `2` uso inválido · `3` 🚨 bloqueio — pré-condição, gramática, git, ferramenta ausente, erro do comando ou timeout. **🚨 nunca equivale a "conforme" nem a "nenhum match".**
- **Saída:** tabelas e listas no stdout; ⚠️ e 🚨 no stderr — para colar tudo num artefato, rode com `2>&1`.
- **Ambiente:** `DOTAGENTS_VERIFY_TIMEOUT` (segundos, inteiro ≥ 1, padrão 60) · `DOTAGENTS_BASE_BRANCH` (branch padrão, quando não é `origin/HEAD`, `main` nem `master`).
- **Fronteira de confiança:** o `PATH` e as ferramentas do executor (`sh`, `git`, `awk`, `grep`, `sed`, `sort`, `cut`, `find`, `tr`, `wc`, `cat`, `head`, `dirname`, `mkdir`, `rm`, `mktemp`, `tar`, `timeout`, `rg`) são confiáveis; o conteúdo de `memories/`, o INDEX e os nomes e conteúdos dos arquivos do repositório não são — por isso só chegam ao shell depois da gramática.
- **Regressão:** no repositório DotAgents, `sh tests/dotagents-verify.test.sh` cobre a gramática, os vetores de ataque, todos os modos e os snippets das skills; `sh tests/dotagents-verify.mutation.sh` prova que cada controle essencial tem teste (remove um por vez e exige que a suíte falhe).

## 1. Coleta de Contexto (Árvore de Decisão)
Fontes: o diff do ciclo e o diretório da task (`task.md`, `qa-report.md`, `review.md`, `security-review.md`). Liste os candidatos a aprendizado e classifique **cada um** respondendo às perguntas abaixo **em ordem**; a primeira resposta "sim" define o tipo (exatamente um):

| # | Pergunta | Sim → Tipo | Destino |
|---|---|---|---|
| 1 | Descreve o que o produto faz, restringe ou permite (regra de negócio, invariante de produto, glossário, permissão)? | `DOMINIO` | `memories/business.md` |
| 2 | Descreve decisão estrutural, contrato (API, schema, evento, integração), NFR, infra, deploy ou ambiente? | `ARQUITETURA` | `memories/architecture.md` |
| 3 | É convenção de código ou antipadrão cuja violação uma forma da gramática do § 2 detecta? | `PADRAO_VERIFICAVEL` | `memories/guidelines.md` |
| 4 | É convenção de design de código que nenhuma forma da gramática do § 2 detecta? | `PADRAO_SEMANTICO` | `memories/guidelines.md` |

- "Não" nas 4 perguntas → **não é memória do projeto**: descarte e liste o descarte no relato final (§ 6).
- `ARQUITETURA` aplica o teste da pergunta 3: decisão detectável por uma forma da gramática (ex.: import proibido entre camadas) → `Verify-Cmd` obrigatório; demais (NFR, infra, deploy) → `N/A — <motivo>`.
- Detecção que exige AST, linter nativo, hook ou teste arquitetural (fora da gramática) → `PADRAO_SEMANTICO` com `N/A — <motivo>` **e** item de backlog (§ 6).

## 2. Template de Entrada (obrigatório)
```markdown
### [AAAA-MM-DD][Task NNN] <título curto>
- **Tipo:** `DOMINIO | ARQUITETURA | PADRAO_VERIFICAVEL | PADRAO_SEMANTICO`
- **Escopo (globs):** `<ex.: src/checkout/**, tests/checkout/** — ou * para global>`
- **Regra:** <aprendizado objetivo em uma linha: SE … ENTÃO … | NUNCA … | SEMPRE …>
- **Verify-Cmd:** `<forma da gramática abaixo>` | `N/A` (DOMINIO) | `N/A — <motivo>` (PADRAO_SEMANTICO e ARQUITETURA não detectável)
- **Origem:** `docs/done/NNN-slug/`
```
- Cada campo ocupa **uma linha** e aparece **uma vez** por entrada (campo repetido → 🚨). Entradas do bootstrap usam `[AAAA-MM-DD][bootstrap]` no título e `` `bootstrap` `` na Origem.
- O `Tipo` acompanha o arquivo: `business.md` só `DOMINIO`, `architecture.md` só `ARQUITETURA`, `guidelines.md` só `PADRAO_*`; fragmento `<segmento>-<tipo>[-N].md` só o Tipo do nome.
- **SUPERSEDED** = título terminando em ` [SUPERSEDED em AAAA-MM-DD]`. Entrada datada sem nenhum campo (formato anterior à v2.3.0) → ⚠️ legada, não executável.

**Escopo (globs):** relativo à raiz do escopo; caracteres `[A-Za-z0-9_.*?/-]`; sem `./`, `/` inicial, `/` final ou segmento `..`; vários globs separados por `, ` (vírgula e espaço), em ordem de bytes (`LC_ALL=C sort`) e sem repetição. Semântica: `**` casa zero ou mais diretórios, `*` casa dentro de um segmento (`*.md` só na raiz), `?` casa um caractere; `*` sozinho = global. O script converte o glob em regex internamente — o glob nunca é passado ao shell nem ao git.

**Gramática do Verify-Cmd (allowlist — nenhuma outra forma é executada):**

| Forma | Sintaxe | Conforme quando |
|---|---|---|
| Proibição | `rg --no-config -q [flags] -e '<regex>' <paths>; test $? -eq 1` | o padrão não ocorre |
| Presença | `rg --no-config -q [flags] -e '<regex>' <paths>` | o padrão ocorre |
| Sem ripgrep | `grep -rqE [-i] [-w] -e '<regex>' <paths>` ou `grep -rqF …` (+ `; test $? -eq 1` para Proibição) | idem |
| Estrutural | `test -e '<path>'` · `test ! -e '<path>'` | o arquivo existe · não existe |

- **flags** (`rg`): apenas `-i`, `-F`, `-w`, `-U`, `-g '<glob>'`, `-t <tipo>`. `--no-config` é obrigatório (neutraliza `RIPGREP_CONFIG_PATH`).
- **`<regex>`** entre aspas simples, sem `'` nem crase (use `\x27` e `\x60`); `-e` garante que o regex nunca é lido como flag.
- **`<paths>`**: relativos, sem `/` inicial; segmento iniciado por `.` exige letra, dígito ou `_` em seguida (bloqueia `..`, inclusive via expansão de `.*`); primeiro segmento nunca inicia por `-` nem `*`.
- **`N/A — <motivo>`**: motivo sem `` ` `` `$` `;` `&` `|` `<` `>` `\` `'` `"`. `N/A` sem motivo só em `DOMINIO`.
- Um Verify-Cmd = **uma** verificação. Duas verificações → duas entradas.

**Execução (no script):** cada comando roda com `sh -c`, stdin fechado e timeout, dentro de um **snapshot** temporário montado pelo próprio git — índice e objetos temporários (`git add -A` + `git checkout-index`), sem alterar o `.git` do repositório e sem que nomes de arquivo passem por shell ou tar — com os arquivos visíveis ao git (rastreados e novos não ignorados, com o conteúdo da working tree) e sem symlinks: arquivos ignorados, `.git/` e alvos de symlink não existem para o Verify-Cmd. A forma `rg` roda com `-uuu`: `.gitignore`, `.ignore`, arquivos ocultos e binários não escondem violações. A busca é interpretada pelo exit bruto: casou / não casou decidem conforme × violação; exit ≥ 2 (regex inválido, path inexistente) é **erro do comando** (🚨, exit 3), nunca violação.

**Validação na escrita (obrigatória — a entrada só permanece gravada se os 3 passos passarem):**
1. Grave a entrada no destino (§ 3) e rode `dotagents-verify.sh lint` → exit 0.
2. **Baseline:** `dotagents-verify.sh run "<título>"` → exit 0 (entrada `N/A`: exit 0 sem executar). Exit 1 → abra item `limpeza+regra` no backlog (§ 6) com as violações existentes e o comando proposto.
3. **Contraprova:** grave um trecho mínimo violador num arquivo temporário **fora do repositório** com a ferramenta de escrita de arquivos (nunca via `printf`/`echo` no shell) e rode `dotagents-verify.sh probe "<título>" <arquivo>` → exit 0 (`N/A` e forma Estrutural: exit 0, contraprova não se aplica — declare no relato). O nome do arquivo usa só `[A-Za-z0-9_./-]` e inicia por letra, dígito, `_`, `.` ou `/` (ex.: o caminho absoluto de um temporário). A contraprova testa o regex; filtros `-g`/`-t` não se aplicam a arquivo explícito.

Qualquer passo com exit ≠ 0 → remova a entrada recém-gravada (ela é do próprio compound e ainda não foi commitada; append-only protege entradas anteriores), corrija e repita 1–3.

## 3. Regras de Escrita
- **Destino:** linha do `INDEX.md` com `Globs` igual ao `Escopo (globs)` da entrada e arquivo `<segmento>-<tipo>[-N].md` do mesmo Tipo → o fragmento. Sem essa linha → o destino da tabela do § 1.
- **Append-only:** nunca reescreva entradas antigas; marque a antiga com ` [SUPERSEDED em AAAA-MM-DD]` no fim do título (nunca apague).
- **Duplicata (determinística):** o `lint` acusa duas entradas ativas com o mesmo `Escopo`, o mesmo `Tipo` e a mesma `Regra` (ignorando maiúsculas e espaços repetidos). Antes de inserir, rode `dotagents-verify.sh list`.
- **Contradição (única decisão semântica do compound):** entrada ativa com o mesmo `Escopo` e o mesmo `Tipo` cuja `Regra` exige o oposto da nova (ex.: `NUNCA X` × `SEMPRE X`) → grave a nova e marque a antiga como SUPERSEDED. Registre cada contradição resolvida no relato (§ 6), com os dois títulos.

## 4. Fragmentação (memories/implementations/)
**Grupo** = linhas de `dotagents-verify.sh list` de um mesmo arquivo global com o mesmo par (`Escopo (globs)`, `Tipo`). Grupo com Escopo `*` nunca é fragmentado.
**Gatilho:** grupo com ≥ 3 entradas → extraia esse grupo. Arquivo global com mais de 300 linhas (`wc -l`) → extraia o maior grupo (empate → menor `Escopo`, depois menor `Tipo`, em ordem de bytes). Nenhum grupo elegível → não fragmente e declare no relato.
- **Nome:** `memories/implementations/<segmento>-<tipo>.md`. `<segmento>` = último segmento sem curinga do primeiro glob (`src/checkout/**` → `checkout`; sem segmento literal, ex. `**/*.sql` → `raiz`); `<tipo>` = Tipo em minúsculas com hífen (`dominio`, `arquitetura`, `padrao-verificavel`, `padrao-semantico`). Nome já usado por outro grupo → sufixo `-2`, `-3`, … (primeiro livre).
- Mova as entradas inteiras (template § 2 intacto) e deixe 1 linha-resumo no arquivo global apontando para o fragmento.
- **Atualize `memories/implementations/INDEX.md`** no mesmo compound (o `lint` acusa fragmento sem linha), uma linha por fragmento:
  `| <arquivo.md> | <globs separados por ", "> | <resumo de 1 linha> | [AAAA-MM-DD] |`
  - **Globs** = união dos `Escopo (globs)` das entradas do fragmento (o `lint` acusa Escopo de entrada fora dos Globs). **Data** = data da última escrita no fragmento.
- **INDEX legado** (linhas fora do formato tabela): o script trata todos os fragmentos como ativos (`*`) e avisa. Converta todas as linhas antes de inserir a nova. Globs = união dos Escopos do fragmento; fragmento sem nenhum Escopo → `*`.
- Feche a fragmentação com `dotagents-verify.sh lint` → exit 0 e `dotagents-verify.sh run "<título>"` → exit 0 para cada entrada movida.

## 5. Regra de Conexão (ativação determinística dos fragmentos)
Fonte única da ativação e da execução — personas, `code-review` e as skills de guardrail apontam para cá.
- **Arquivos do diff:** `git diff --name-only --no-renames --relative <merge-base>` (commitados e não commitados; renomeação conta como deleção + adição) ∪ `git ls-files --others --exclude-standard` (novos não ignorados), relativos ao diretório onde o script roda. `<merge-base>` = `git merge-base HEAD <branch padrão>`. A branch padrão é resolvida só por refs completos — o primeiro de `refs/remotes/origin/HEAD`, `refs/heads/main`, `refs/heads/master` que existe, ou `refs/heads/<DOTAGENTS_BASE_BRANCH>` / `refs/remotes/<DOTAGENTS_BASE_BRANCH>` —, de modo que uma tag homônima vinda do remoto nunca sombreia a branch; nenhum resolve → 🚨.
- **Ativação:** um fragmento está **ativo** quando algum glob da sua linha no `INDEX.md` casa algum path considerado (ou é `*`). O script imprime `FRAGMENTO ATIVO: <arquivo>` ou `FRAGMENTOS ATIVOS: nenhum`.
- **Leitura obrigatória:** qualquer agente (Architect, Tech Lead, Developer, Reviewer) que planejar ou editar um arquivo cujo path dê match em um glob listado no `INDEX.md` é **OBRIGADO** a ler o fragmento correspondente antes de gerar seu artefato.
  - **PO e Architect** (sem shell): paths planejados = paths citados na `## Demanda` e no `## Gate de Completude`, comparados textualmente aos globs pela semântica do § 2. O Architect registra o resultado em `## Notas do Architect` → `**Fragmentos ativados:**` (`nenhum` quando não houver).
  - **Tech Lead (planejamento):** `dotagents-verify.sh fragments <arquivos dos cabeçalhos ### Grupo Gn — arquivos: do Checklist>` (o script remove `./` inicial e `,` final de cada path).
  - **Developer e Reviewer:** `dotagents-verify.sh diff 2>&1`.
- **Execução dos Verify-Cmd** (`dotagents-verify.sh diff`): o script roda o `lint` antes de tudo (qualquer 🚨 → nenhum comando é executado) e executa, no snapshot do § 2, as entradas ativas com Verify-Cmd executável de `memories/guidelines.md`, `memories/architecture.md` e dos fragmentos ativos cujo `Escopo (globs)` casa algum arquivo do diff (ou é `*`). A saída é a tabela **comando + exit code** do artefato do executor (`review.md § Verificações Determinísticas` ou § Evidências). Entrada marcada SUPERSEDED pelo próprio diff gera ⚠️ (confirme a entrada substituta); entrada removida ou com `Tipo`, `Escopo` ou `Verify-Cmd` alterado pelo diff gera ⚠️ (confirme que a regra não foi enfraquecida).
- **Pré-condições do script** (exit 3): para os modos de memória, `memories/` presente, sem symlink ou arquivo especial, nomes só com `[A-Za-z0-9_./-]` e fim de linha LF (CRLF → 🚨); para os modos com diff, raiz do escopo ou do repositório, merge-base resolvido, `git diff`/`git ls-files` com exit 0 e nenhum nome com quebra de linha ou caractere de controle.
- **Verificador em execução alterado** (autoverificação, em todos os modos que usam git, inclusive `run` e `probe`): o script compara o **próprio arquivo em execução** com o merge-base. Dentro do repositório e diferente da versão do merge-base (diff que altera o verificador, inclusive a **atualização** da squad que muda o script) → 🚨, porque a cópia da working tree não é confiável: rode a versão do merge-base fora do repositório — `git show <merge-base>:<caminho do verificador> > <arquivo fora do repo>` e `sh <arquivo> <modo>` — e revise a mudança do script manualmente no review. Sem versão no merge-base (**instalação** da squad nesta branch) → ⚠️ e a execução segue; registre a revisão manual em Ressalvas. A cópia rodando fora do repositório não se checa.

## 6. Encerramento do Ciclo
1. **Promoção para automação do projeto:** o compound não altera código pós-Ops. Aprendizado que exige AST, linter nativo, hook ou teste arquitetural fora de `memories/` (ou item `limpeza+regra` do § 2) → registre em `docs/todo/backlog-compound.md` (append; crie o arquivo com o título `# Backlog do Compound` se ausente):
   ```markdown
   ### BC-NNN [AAAA-MM-DD][Task NNN] <título curto>
   - **Automação:** linter | hook | teste arquitetural | limpeza+regra
   - **Especificação:** <ferramenta, arquivo de configuração alvo, regra técnica e comportamento esperado>
   - **Verify-Cmd proposto:** `<forma da gramática do § 2>` | `N/A`
   - **Origem:** `docs/done/NNN-slug/`
   - **Puxar com:** `/dot-agent-new-feature Implementar BC-NNN de docs/todo/backlog-compound.md`
   - **Status:** aberto
   ```
   `BC-NNN` = maior BC existente no arquivo + 1 (3 dígitos). O Verify-Cmd proposto só entra em memória pelo § 2 (lint + baseline + contraprova) quando o item é puxado. **Puxar com** usa o atalho `{{AGENTS_ROOT}}/commands/dot-agent-new-feature.md`; a mesma frase sem o atalho entra pelo Manager. O PO, ao criar a task a partir do item (persona `product-owner` § 1), troca o Status do item para `puxado (task NNN)`.
2. Remova `docs/todo/.dotagents-bypass` se existir (fecha o opt-out do ciclo).
3. **Relato ao usuário** (bloco único): entradas gravadas (tipo → arquivo), Verify-Cmd validados (exit do `lint`, do `run` e do `probe`), contradições resolvidas (§ 3), descartes do § 1, fragmentações (ou "nenhum grupo elegível") e, para cada item de backlog aberto, o comando exato do campo **Puxar com**.

## Restrições
- Compound **NÃO** altera código de produção nem suíte de testes. Escreve apenas em `memories/` (memórias globais, fragmentos e `INDEX.md`) e em `docs/todo/backlog-compound.md`, e remove `docs/todo/.dotagents-bypass` — caminhos liberados pelo `dotagents-gate.sh`.
- **Violação do protocolo de memória acusada pelo `lint`:** título sem `[AAAA-MM-DD][Task NNN]` ou `[AAAA-MM-DD][bootstrap]`; `Tipo`, `Escopo (globs)`, `Regra` ou `Origem` ausente ou fora do formato; campo repetido; `Tipo` incompatível com o arquivo; Escopo fora de ordem ou com glob repetido; `Verify-Cmd` fora da gramática; `N/A` em `PADRAO_VERIFICAVEL`; `N/A` sem motivo fora de `DOMINIO`; Verify-Cmd diferente de `N/A` em `DOMINIO` (executável ou `N/A — <motivo>`); entrada duplicada; data impossível no título; fragmento sem linha no INDEX ou em mais de uma linha; linha do INDEX fora do formato de 4 colunas, apontando fragmento inexistente, com Globs fora da gramática, sem resumo ou com data fora de `[AAAA-MM-DD]`; Escopo de entrada de fragmento fora dos Globs do INDEX.
- **Violação não detectável pelo `lint`** (o compound garante pelos passos do § 1 e do § 2): `ARQUITETURA` detectável por busca estática sem Verify-Cmd; entrada gravada sem baseline exit 0 ou sem contraprova.
