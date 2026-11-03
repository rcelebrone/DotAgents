---
name: compound
description: Engenharia Composta (Compounding Engineering) e construção de Harness determinístico ao final de cada ciclo. Transforma aprendizados, feedbacks do usuário, consolidações autônomas e oportunidades de melhoria aprovadas em guardrails determinísticos executáveis + memória viva. Executada obrigatoriamente pelo Tech Lead após o PO definir Status entregue.
---

# Skill: Compound (Compounding Engineering & Harness Builder)

Executada **obrigatoriamente** pelo **Tech Lead** em todo fechamento de ciclo quando a task atinge Status `entregue`.

> **Princípio Fundamental (Inferência → Determinismo):** Aprender não é apenas anotar texto em markdown esperando que um LLM leia e obedeça no próximo ciclo. **Compounding Engineering** significa que cada ciclo concluído torna o próximo ciclo mais seguro, rápido e à prova de falhas através da construção ativa do **Harness** (guardrails determinísticos baseados em código, linters, testes, AST, configs e scripts de verificação com exit code).

---

## 1. Coleta de Insumos (As 4 Fontes Obrigatórias de Aprendizado)

Antes de fechar o ciclo, varra sistematicamente o diff, o histórico da conversa e os artefatos da task (`task.md`, `qa-report.md`, `review.md`, `security-review.md`) buscando **exatamente** estas 4 fontes:

### Fonte A — Correções e Feedbacks Diretos do Usuário
Qualquer intervenção, correção de rumo ou preferência expressa pelo usuário durante o ciclo.
- *Exemplos:* "use a biblioteca X no lugar de Y", "faltou configurar o linter Z", "não use default export", "valide sempre o schema com Zod na borda".
- **Regra:** Todo feedback corretivo do usuário **DEVE** gerar um guardrail determinístico no harness + registro em memória para que ele nunca precise repetir a mesma correção.

### Fonte B — Decisões de Qualidade e Cobertura Tomadas no Ciclo
Resoluções de dilemas levantados pelos agentes de validação (QA, Security, Tech Lead).
- *Exemplo clássico (Cobertura/Testes):* O QA Specialist identificou ausência de testes ou cobertura abaixo do ideal e perguntou ao usuário se deveria seguir assim ou cobrir com testes:
  - **Se o usuário determinou cobrir com testes:** o `compound` deve garantir que os ciclos seguintes exijam testes de forma determinística (configurando/ativando threshold no runner de cobertura da stack, script de `coverage-gate` e registrando a baseline em `memories/architecture.md § Testes e Cobertura`).
  - **Se o usuário aceitou seguir sem cobrir naquele momento:** registre a decisão/dívida técnica com escopo claro, sem bloquear o fechamento.

### Fonte C — Oportunidades de Melhoria dos Revisores (Aprovadas pelo Usuário)
Os agentes de validação (`qa-specialist`, `security`, `ops`, `techlead`) têm o dever de observar **ao menos 1 oportunidade de melhoria** em suas revisões (`## Oportunidades de Melhoria (Insumo Compound)`).
- **Filtro de aprovação:** Verifique a decisão do usuário sobre cada oportunidade apresentada no fechamento/review:
  - **APROVADA pelo usuário (`[x] Aprovada`):** transforma-se **obrigatoriamente** em guardrail determinístico no harness + entrada na memória.
  - **REJEITADA pelo usuário (`[x] Rejeitada`):** **NÃO** implemente o guardrail. Registre o encerramento do ciclo normalmente (anti-loop infinito: a rejeição do usuário encerra a discussão daquela sugestão imediatamente).

### Fonte D — Consolidações e Boas Práticas Evidentes (Autônomas)
Melhorias técnicas óbvias realizadas durante o desenvolvimento (pelo Developer, Architect ou Tech Lead) que refletem higiene e sã engenharia inquestionável.
- *Exemplos:* O Developer percebeu duas bibliotecas para o mesmo propósito (ex.: `axios` e `node-fetch`, `moment` e `date-fns`) e normalizou para uma só; remoção de configuração duplicada; padronização de tratamento de erro óbvio.
- **Regra de Autonomia (Sem Pergunta Desnecessária):** Para boas práticas evidentes já aplicadas no ciclo, **NÃO é necessário perguntar ao usuário antes de consolidar**. O Tech Lead cria o guardrail determinístico diretamente (ex.: regra `no-restricted-imports` bloqueando a lib preterida) e **apenas informa** no resumo final do ciclo que tomou a decisão de consolidar o aprendizado e blindar o harness.

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

## 3. Persistência nas Memórias Vivas (`memories/`)

Além do guardrail físico no projeto, todo aprendizado consolidado é registrado na memória correspondente (documentando **a regra** e **qual guardrail determinístico a protege**):

### Template de Entrada (obrigatório)
```markdown
### [AAAA-MM-DD][Task NNN] <título curto>
- **Aprendizado / Regra:** <o que aprendemos em 1–3 linhas>
- **Fonte:** [Feedback do Usuário | Decisão de QA/Review | Melhoria Aprovada | Consolidação Autônoma]
- **Harness (Guardrail Determinístico):** <arquivo de config/regra/script criado ou atualizado + comando que valida>
- **Origem:** docs/done/NNN-slug/
```

### Regras de Escrita em Memória
- **Destino pela fronteira:**
  - Regra de domínio / funcional → `memories/business.md`
  - Decisão arquitetural / NFR / infra / baseline de cobertura / comandos de build & smoke → `memories/architecture.md`
  - Convenção de código / antipadrão / libs banidas / regras de lint → `memories/guidelines.md`
- **Append-only:** nunca apague entradas antigas. Se o novo aprendizado substitui uma decisão anterior, adicione a nova entrada e marque a antiga com `[SUPERSEDED em AAAA-MM-DD]`.
- **Dedup:** antes de inserir, faça `grep` pelo termo-chave — se já existe entrada equivalente, atualize via `SUPERSEDED` ou complemente sem duplicar.

### Fragmentação (`memories/implementations/`)
Gatilho: memória global passou de ~300 linhas OU acumulou ≥ 3 entradas do mesmo tópico específico.
- Extraia o tópico para `memories/implementations/<dominio>-<topico>.md` (ex.: `checkout-rules.md`, `redis-setup.md`).
- Deixe 1 linha-resumo no arquivo global apontando para o fragmento.
- **Atualize `memories/implementations/INDEX.md`** (`arquivo.md` — resumo — `[AAAA-MM-DD]`).

---

## 4. Prevenção de Loop Infinito (Regra de Terminação Estrita)

O ciclo de `compound` **NUNCA** pode reabrir a task ou gerar um loop infinito de melhorias:
1. **Execução Única por Ciclo:** O `compound` roda **uma única vez** ao final da task (após `Status: entregue`).
2. **Soberania do Usuário sobre Sugestões:** Se o usuário **rejeitar** uma oportunidade de melhoria sugerida por QA, Security, Ops ou Tech Lead, a sugestão é descartada imediatamente (ou anotada apenas como nota histórica se relevante, **sem** criar guardrail e **sem** insistir). O ciclo fecha imediatamente.
3. **Escopo do Harness:** Os guardrails criados pelo `compound` devem ser configurações diretas, regras de lint, thresholds de cobertura ou scripts de verificação leves. Se uma melhoria aprovada pelo usuário exigir uma refatoração massiva de arquitetura ou uma nova feature complexa, o `compound` cria o guardrail preventivo para códigos novos e abre uma **nova task P2/P3** em `docs/todo/` para o backlog — **sem impedir o fechamento da task atual**.
4. **Commit de Harness (quando houver alteração de arquivos de config/guardrail):** Se o `compound` gerou ou atualizou arquivos de configuração do projeto (ex.: `.eslintrc`, `jest.config`, `pyproject.toml`, scripts de verificação), consolide essas alterações em um commit semântico `chore(harness): consolidar guardrails deterministicos da Task NNN` (validado pelo `semantic-commit-checker`).

---

## 5. Encerramento do Ciclo, Branch, Pull Request e Relatório de Compounding

1. **Limpeza de Bypass:** Remova `docs/todo/.dotagents-bypass` se existir.
2. **Arquivamento:** Acione a skill `task-tracker` para mover `docs/todo/<NNN-slug>/` para `docs/done/<NNN-slug>/` (garantindo que os artefatos e decisões fiquem preservados).
3. **Commit Final, Push da Branch e Pull Request (PR):**
   - Certifique-se de que todo o trabalho do ciclo + guardrails do `compound` + memórias atualizadas estão em uma **branch à parte baseada na branch principal** (`<tipo>/NNN-slug` a partir de `main`/`master`).
   - Se o `compound` gerou alterações (guardrails, memórias, arquivamento da task em `docs/done/`), faça o commit semântico na branch da task (`chore(compound): consolidar harness deterministico e memorias da Task NNN`, validado pelo `semantic-commit-checker`).
   - Faça o push da branch (`git push -u origin <tipo>/NNN-slug`) e **gere ou atualize o Pull Request (PR)** para a branch principal (`gh pr create --base main --head <tipo>/NNN-slug ...`), documentando no corpo do PR a implementação e os guardrails determinísticos adicionados ao harness.
4. **Relatório Final ao Usuário (obrigatório):** Apresente de forma concisa o que o projeto aprendeu, como o harness evoluiu neste ciclo e o link do PR gerado:

```markdown
🧬 **Compound Concluído — Task NNN**
- **Branch / PR:** `<tipo>/NNN-slug` → PR `#XX` (<link do PR>)
- **Memórias atualizadas:** `<arquivos em memories/>`
- **Guardrails Determinísticos (Harness) criados/atualizados:**
  - 🔒 `<regra/config/threshold implementado>` (Fonte: `<Usuário | QA/Security/Ops/TL | Autônomo>`) → validado via `<comando>`
- **Sugestões descartadas (decisão do usuário):** `<nenhuma | lista curta>`
```

---

## Restrições
- **Proibido aprendizado puramente passivo quando cabe guardrail:** Se um erro ou antipadrão pode ser barrado por linter, type-check, teste de cobertura ou trava de dependência, escrever apenas em `memories/guidelines.md` sem configurar a ferramenta determinística é execução incompleta desta skill.
- **Respeito absoluto ao "Não" do usuário:** Sugestão rejeitada pelo usuário jamais vira bloqueio ou reabertura de ciclo.
- Entrada em memória sem data `[AAAA-MM-DD]` ou sem proveniência `[Task NNN]` é violação do protocolo.
