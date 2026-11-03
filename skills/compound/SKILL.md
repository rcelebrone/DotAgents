---
name: compound
description: Engenharia Composta (Compounding Engineering), construção de Harness determinístico e Rede Neural de Memórias (nós atômicos interconectados com headers semânticos) ao final de cada ciclo. Transforma aprendizados, feedbacks do usuário, consolidações autônomas e oportunidades de melhoria aprovadas em guardrails determinísticos executáveis + nós de memória otimizados para tokens. Executada obrigatoriamente pelo Tech Lead após o PO definir Status entregue.
---

# Skill: Compound (Compounding Engineering, Harness Builder & Synaptic Memory)

Executada **obrigatoriamente** pelo **Tech Lead** em todo fechamento de ciclo quando a task atinge Status `entregue`.

> **Princípio Fundamental 1 (Inferência → Determinismo):** Aprender não é apenas anotar texto em markdown esperando que um LLM leia e obedeça no próximo ciclo. **Compounding Engineering** significa que cada ciclo concluído torna o próximo ciclo mais seguro, rápido e à prova de falhas através da construção ativa do **Harness** (guardrails determinísticos baseados em código, linters, testes, AST, configs e scripts de verificação com exit code).
>
> **Princípio Fundamental 2 (Memória Sináptica & Token Optimization):** NUNCA acumule aprendizados de ciclos em um único arquivo monolítico que obrigue as IAs a lerem centenas de linhas desnecessárias. As memórias do projeto funcionam como um **cérebro (rede neural de arquivos pequenos e interconectados)**: cada assunto/componente/fluxo vive em um **nó atômico** (`memories/implementations/<id-do-no>.md`) equipado com um **Header Semântico (YAML Frontmatter)** que explica exatamente o conteúdo do arquivo e lista suas **sinapses (`connections`)** com outros nós. Os agentes leem primeiro o índice/headers (~15 linhas) e carregam apenas os nós relevantes e suas conexões diretas.

---

## 1. Coleta de Insumos (As 4 Fontes Obrigatórias de Aprendizado)

Antes de fechar o ciclo, varra sistematicamente o diff, o histórico da conversa e os artefatos da task (`task.md`, `qa-report.md`, `review.md`, `security-review.md`) buscando **exatamente** estas 4 fontes:

### Fonte A — Correções e Feedbacks Diretos do Usuário
Qualquer intervenção, correção de rumo ou preferência expressa pelo usuário durante o ciclo.
- *Exemplos:* "use a biblioteca X no lugar de Y", "no botão de pagamento valide antes o saldo", "faltou configurar o linter Z", "não use default export".
- **Regra:** Todo feedback corretivo do usuário **DEVE** gerar um guardrail determinístico no harness + um nó atômico (ou atualização de nó) na rede de memória, interconectado aos assuntos correlatos.

### Fonte B — Decisões de Qualidade e Cobertura Tomadas no Ciclo
Resoluções de dilemas levantados pelos agentes de validação (QA, Security, Tech Lead).
- *Exemplo clássico (Cobertura/Testes):* O QA Specialist identificou ausência de testes ou cobertura abaixo do ideal e perguntou ao usuário se deveria seguir assim ou cobrir com testes:
  - **Se o usuário determinou cobrir com testes:** o `compound` garante que os ciclos seguintes exijam testes de forma determinística (configurando/ativando threshold no runner de cobertura da stack, script de `coverage-gate` e registrando a baseline em `memories/architecture.md § Testes e Cobertura` + nó de memória se aplicável).
  - **Se o usuário aceitou seguir sem cobrir naquele momento:** registre a decisão/dívida técnica com escopo claro, sem bloquear o fechamento.

### Fonte C — Oportunidades de Melhoria dos Revisores (Aprovadas pelo Usuário)
Os agentes de validação (`qa-specialist`, `security`, `ops`, `techlead`) têm o dever de observar **ao menos 1 oportunidade de melhoria** em suas revisões (`## Oportunidades de Melhoria (Insumo Compound)`).
- **Filtro de aprovação:** Verifique a decisão do usuário sobre cada oportunidade apresentada no fechamento/review:
  - **APROVADA pelo usuário (`[x] Aprovada`):** transforma-se **obrigatoriamente** em guardrail determinístico no harness + nó na rede de memória.
  - **REJEITADA pelo usuário (`[x] Rejeitada`):** **NÃO** implemente o guardrail. Registre o encerramento do ciclo normalmente (anti-loop infinito: a rejeição do usuário encerra a discussão daquela sugestão imediatamente).

### Fonte D — Consolidações e Boas Práticas Evidentes (Autônomas)
Melhorias técnicas óbvias realizadas durante o desenvolvimento (pelo Developer, Architect ou Tech Lead) que refletem higiene e sã engenharia inquestionável.
- *Exemplos:* O Developer percebeu duas bibliotecas para o mesmo propósito (ex.: `axios` e `node-fetch`, `moment` e `date-fns`) e normalizou para uma só; remoção de configuração duplicada; padronização de tratamento de erro óbvio.
- **Regra de Autonomia (Sem Pergunta Desnecessária):** Para boas práticas evidentes já aplicadas no ciclo, **NÃO é necessário perguntar ao usuário antes de consolidar**. O Tech Lead cria o guardrail determinístico diretamente (ex.: regra `no-restricted-imports` bloqueando a lib preterida), cria/atualiza o nó de memória e **apenas informa** no resumo final do ciclo que tomou a decisão de consolidar o aprendizado e blindar o harness.

---

## 2. Matriz de Transformação: Aprendizado → Harness Determinístico

Para cada aprendizado validado nas Fontes A, B, C (aprovadas) ou D, aplique a regra: **"Se pode ser verificado por máquina (Exit Code != 0), NÃO deve depender apenas de leitura de prompt."**

Escolha e **implemente fisicamente no projeto** o mecanismo determinístico mais adequado:

| Tipo de Aprendizado / Ocorrência | Guardrail Determinístico a Implementar no Projeto (Harness) | Skill / Gate Relacionado |
|---|---|---|
| **Biblioteca preterida / normalização de pacotes** (ex.: usar lib A em vez de B, banir import X) | Adicionar regra `no-restricted-imports` / `no-restricted-modules` no ESLint/Biome, `banned-api` no Ruff/Flake8, `depguard` no golangci-lint, ou verificação em script de lint do projeto. | `linter-enforcer` / `dependency-lock` |
| **Ausência de testes / Exigência de cobertura aprovada** | Configurar `coverageThreshold` no `jest.config` / `vitest.config`, `--cov-fail-under=X` no `pyproject.toml`/`pytest.ini`, ou script de verificação matemática; atualizar baseline em `memories/architecture.md`. | `coverage-gate` / `test-scaffold` |
| **Ausência de Linter / Regra de formatação ou estilo corrigida** | Criar ou atualizar arquivo de configuração do linter (`.eslintrc`, `biome.json`, `ruff.toml`, `.golangci.yml`) ativando a regra com severidade `error` (zero warnings) e garantir script `lint` no manifesto. | `linter-enforcer` |
| **Erro de tipagem / Símbolo inexistente / Contrato quebrado** | Ativar flags estritas no compilador/type-checker (`strict: true` no `tsconfig.json`, `disallow_untyped_defs` no `mypy.ini`) ou criar teste de contrato/schema. | `ast-validator` |
| **Vulnerabilidade / Segredo / Configuração insegura detectada** | Adicionar regra de SAST/linter de segurança, atualizar `.gitignore`/`.env.example`, adicionar checagem de configuração no script de smoke/verificação. | `security-audit` / `dependency-lock` |
| **Falha de build / Ambiente / Smoke ou Deploy** | Atualizar script de build/smoke executável no manifesto (`package.json`, `Makefile`, etc.) e registrar comando exato em `memories/architecture.md § Deploy`. | `delivery` / `ops` |
| **Convenção arquitetural / Fronteira entre camadas** (ex.: domínio não importa infra) | Configurar regra de fronteira de importação no linter ou adicionar verificação determinística no script de check do repositório + ADR se estrutural. | `guard` / `ast-validator` |

> **Verificação Obrigatória do Guardrail:** Após criar ou editar qualquer regra de linter, config de cobertura ou script de verificação, **execute o comando no terminal** para provar que o guardrail está ativo, válido e passando (`Exit Code 0`) no estado atual do repositório.

---

## 3. Arquitetura de Memória Sináptica (Pequenos Arquivos Interconectados)

Para otimizar drasticamente o consumo de tokens e a janela de contexto dos modelos de IA, as memórias **NÃO** são acumuladas como listas longas em um único arquivo. Elas são estruturadas como um **Grafo Sináptico (Cérebro)**:

1. **Hubs Raiz Enxutos (`memories/business.md`, `memories/architecture.md`, `memories/guidelines.md`):**
   - Contêm **apenas** a visão macro invariante do projeto (resumo da stack, comandos globais de build/test/deploy, tom de voz, glossário core) e **ponteiros curtos (1 linha)** para os nós atômicos.
   - Limite estrito: cada arquivo raiz deve permanecer enxuto (~50–100 linhas). Qualquer regra específica de feature, componente, módulo, feedback de UI/API ou guardrail de domínio vai direto para um **Nó de Memória** em `memories/implementations/<id-do-no>.md`.

2. **Nós Atômicos de Memória (`memories/implementations/<dominio>-<assunto>.md`):**
   - Cada aprendizado ou contexto específico (ex.: `payment-button-ui.md`, `checkout-gateway.md`, `http-client-policy.md`, `auth-session-rules.md`) vive em um arquivo pequeno (idealmente **30 a 80 linhas**).
   - **Header Semântico Obrigatório (YAML Frontmatter):** as primeiras linhas do arquivo DEVEM conter o cabeçalho estruturado para que qualquer agente possa inspecionar apenas o topo do arquivo (`head -n 20` ou leitura de linhas 1–20) e decidir se precisa ler o corpo ou navegar para os nós conectados:

```markdown
---
id: <dominio>-<assunto>
type: business | architecture | guideline
domain: <dominio-principal>
tags: [<tag1>, <tag2>, <tag3>]
summary: "<Resumo de 1 linha explicando exatamente o que este nó governa para que a IA saiba se precisa ler o arquivo>"
when_to_read: "<Gatilho claro: ex. Ao tocar em componentes de botão de pagamento, checkout ou eventos de clique de compra>"
connections:
  - target: <id-de-outro-no>
    relation: "<ex.: valida-com | depende-de | compartilha-estado | restringe | aciona>"
    reason: "<Por que a IA que lê este arquivo pode precisar ler o outro — conexão sináptica>"
harness:
  - "<caminho/do/arquivo-de-config-ou-regra-deterministica>"
updated_at: AAAA-MM-DD
tasks: [NNN]
---

# <Título do Nó de Memória>

### [AAAA-MM-DD][Task NNN] <Título curto do aprendizado>
- **Aprendizado / Regra:** <o que aprendemos em 1–3 linhas>
- **Fonte:** [Feedback do Usuário | Decisão de QA/Review | Melhoria Aprovada | Consolidação Autônoma]
- **Harness (Guardrail Determinístico):** `<regra/config/script criado>` (validado via `<comando>`)
- **Origem:** `docs/done/NNN-slug/`
```

3. **Sinapses Bidirecionais (Conexões Cerebrais):**
   - Sempre que criar um nó novo (ex.: `payment-button.md` após feedback do usuário no botão de pagamento) e perceber que ele se relaciona com outro assunto existente (ex.: `stripe-webhook.md` ou `currency-formatting.md`), **adicione a conexão no `connections:` de AMBOS os arquivos** (ou do nó de origem apontando para o destino e atualizando o índice).
   - Assim, quando um agente no futuro for alterar o botão de pagamento e ler `payment-button.md`, o próprio header o avisará: *"Este assunto tem conexão sináptica com `stripe-webhook` (aciona cobrança assíncrona) e `error-toast-guideline` (padrão de feedback visual)"*.

4. **Mapa Sináptico Central (`memories/implementations/INDEX.md`):**
   - Funciona como o córtex de roteamento rápido. Deve ser mantido rigorosamente atualizado com uma tabela de leitura ultrarrápida contendo: `Nó (Arquivo)` | `Tipo` | `Summary (O que contém)` | `Sinapses (Conexões ↔)` | `Harness` | `Atualizado`.
   - **Regra de Leitura Seletiva para os Agentes:** NENHUM agente deve ler todos os arquivos de `memories/implementations/`. O protocolo de qualquer agente (PO, Architect, TL, Developer, QA, Security) é:
     1. Ler `memories/implementations/INDEX.md`;
     2. Inspecionar os headers (`StartLine: 1, EndLine: 20`) dos nós candidatos;
     3. Ler o corpo completo **apenas** dos nós cujo `when_to_read`/`summary` corresponda à task atual e seguir as `connections` no header se a alteração impactar a fronteira apontada.

5. **Regras de Manutenção dos Nós:**
   - **Append-only / Supersedence:** dentro de um nó atômico, se uma decisão mudar, marque a entrada anterior com `[SUPERSEDED em AAAA-MM-DD]` e adicione a nova + atualize o `summary` e `updated_at` no header YAML.
   - **Fissão Celular (Split):** se um nó em `memories/implementations/` passar de ~100 linhas ou começar a misturar 2 sub-assuntos distintos, divida-o em 2 nós menores e conecte-os via `connections:` no header!

---

## 4. Prevenção de Loop Infinito (Regra de Terminação Estrita)

O ciclo de `compound` **NUNCA** pode reabrir a task ou gerar um loop infinito de melhorias:
1. **Execução Única por Ciclo:** O `compound` roda **uma única vez** ao final da task (após `Status: entregue`).
2. **Soberania do Usuário sobre Sugestões:** Se o usuário **rejeitar** uma oportunidade de melhoria sugerida por QA, Security, Ops ou Tech Lead, a sugestão é descartada imediatamente (sem criar guardrail e sem insistir). O ciclo fecha imediatamente.
3. **Escopo do Harness:** Os guardrails criados pelo `compound` devem ser configurações diretas, regras de lint, thresholds de cobertura ou scripts de verificação leves. Se uma melhoria aprovada pelo usuário exigir uma refatoração massiva de arquitetura ou uma nova feature complexa, o `compound` cria o guardrail preventivo para códigos novos e abre uma **nova task P2/P3** em `docs/todo/` para o backlog — **sem impedir o fechamento da task atual**.

---

## 5. Encerramento do Ciclo, Branch, Pull Request e Relatório de Compounding

1. **Limpeza de Bypass:** Remova `docs/todo/.dotagents-bypass` se existir.
2. **Arquivamento:** Acione a skill `task-tracker` para mover `docs/todo/<NNN-slug>/` para `docs/done/<NNN-slug>/` (garantindo que os artefatos e decisões fiquem preservados).
3. **Commit Final, Push da Branch e Pull Request (PR):**
   - Certifique-se de que todo o trabalho do ciclo + guardrails do `compound` + nós de memória atualizados estão em uma **branch à parte baseada na branch principal** (`<tipo>/NNN-slug` a partir de `main`/`master`).
   - Se o `compound` gerou alterações (guardrails, nós de memória, `INDEX.md`, arquivamento da task em `docs/done/`), faça o commit semântico na branch da task (`chore(compound): consolidar harness deterministico e memorias da Task NNN`, validado pelo `semantic-commit-checker`).
   - Faça o push da branch (`git push -u origin <tipo>/NNN-slug`) e **gere ou atualize o Pull Request (PR)** para a branch principal (`gh pr create --base main --head <tipo>/NNN-slug ...`), documentando no corpo do PR a implementação, os nós de memória criados/conectados e os guardrails determinísticos adicionados ao harness.
4. **Relatório Final ao Usuário (obrigatório):** Apresente de forma concisa o que o projeto aprendeu, os nós/sinapses criados, como o harness evoluiu neste ciclo e o link do PR gerado:

```markdown
🧬 **Compound Concluído — Task NNN**
- **Branch / PR:** `<tipo>/NNN-slug` → PR `#XX` (<link do PR>)
- **Nós de Memória & Sinapses (`memories/implementations/`):**
  - 🧠 `<no-1.md>` (`<type>`) ↔ conectado a `[<no-2.md>, ...]`
- **Guardrails Determinísticos (Harness) criados/atualizados:**
  - 🔒 `<regra/config/threshold implementado>` (Fonte: `<Usuário | QA/Security/Ops/TL | Autônomo>`) → validado via `<comando>`
- **Sugestões descartadas (decisão do usuário):** `<nenhuma | lista curta>`
```

---

## Restrições
- **Proibido aprendizado puramente passivo quando cabe guardrail:** Se um erro ou antipadrão pode ser barrado por linter, type-check, teste de cobertura ou trava de dependência, escrever apenas em memória sem configurar a ferramenta determinística é execução incompleta desta skill.
- **Proibido acumular memórias em arquivo único:** Aprendizados específicos de ciclo DEVEM ser gravados em nós atômicos com Header Semântico YAML e `connections` em `memories/implementations/`, mantendo os arquivos raiz enxutos.
- **Respeito absoluto ao "Não" do usuário:** Sugestão rejeitada pelo usuário jamais vira bloqueio ou reabertura de ciclo.
- Entrada em memória sem data `[AAAA-MM-DD]` ou sem proveniência `[Task NNN]` é violação do protocolo.
