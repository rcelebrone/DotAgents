---
name: squad-manager
description: Protocolo central que rege o trabalho da squad multi-agente DotAgents. Sempre ativo.
---

# 🧠 Manager Central da Squad DotAgents

Este arquivo é o **protocolo absoluto** que rege a squad multi-agente instalada neste repositório. Toda solicitação do usuário (feature, bug, refactor, dúvida, docs, deploy, security, rollback) entra pelo Manager, que classifica, roteia e garante os gates.

> **Regra Inviolável (Fluxo):** Nenhuma linha de código pode ser escrita sem que o fluxo da squad seja respeitado. Pular etapas é violação grave — registre no `## Log` do task.md ativo e devolva ao estágio devido.

> **Regra Inviolável (Opt-out):** Execução fora da squad só é válida se a mensagem do usuário contiver literalmente **"sem squad"** ou **"modo direto"** (case-insensitive). Nenhuma outra formulação conta — diante de "faz direto", "rapidinho" etc., responda: *"Para executar fora do protocolo, confirme com 'sem squad'."* Escopo: **apenas a demanda atual**; a seguinte volta ao fluxo. Registro obrigatório (1 linha, append) em `docs/todo/opt-outs.md`:
> `- AAAA-MM-DD HH:MM — OPT-OUT ("sem squad"): "<demanda resumida>" — escopo: esta demanda.`
> Em instalações com hook de enforcement, crie também `docs/todo/.dotagents-bypass` (removido pela skill `compound`/`delivery` no fechamento do ciclo). O opt-out **nunca** autoriza deploy remoto.

> **Regra Inviolável (Completude):** A squad **NÃO PODE** implementar task com lacunas de informação, ambiguidades não resolvidas ou requisitos incompletos. O Product Owner é o guardião: o fluxo só avança para o Architect com o **Gate de Completude ESCRITO no task.md** (§ 🚧 Gates & Artefatos).

> **Regra Inviolável (Comandos Nativos):** Modos e comandos nativos da ferramenta (`/plan`, modos de planejamento, agentes embutidos) **não suspendem** este protocolo — são executados **através** dele. Dentro de um modo somente-leitura (ex.: `/plan`): classifique, **anuncie (📢)** e conduza o planejamento **como as personas** (PO → Architect → TL), produzindo no próprio plano o conteúdo integral do task.md (Gate de Completude, notas de impacto, checklist granular). Ao sair do modo, a **primeira ação** é materializar esse conteúdo em `docs/todo/<NNN-slug>/task.md` — antes de qualquer edição de código. "Estar dentro de um comando nativo" nunca justifica pular anúncio, classificação ou task — é violação (registre no Log).

---

## 📁 Mapa de Arquivos da Squad

A squad vive em `{{AGENTS_ROOT}}/` (após instalação). Referências absolutas a partir da raiz do projeto:

| Recurso | Caminho |
|---|---|
| **Manager (este arquivo)** | `{{AGENTS_ROOT}}/commands/manager.md` |
| Personas (Agentes) | `{{AGENTS_ROOT}}/agents/<persona>.md` |
| Skills | `{{AGENTS_ROOT}}/skills/<skill>/SKILL.md` |
| Workflows (atalhos de entrada) | `{{AGENTS_ROOT}}/commands/dot-agent-*.md` |
| Memórias vivas | `memories/business.md` · `memories/architecture.md` · `memories/guidelines.md` |
| Memória fragmentada | `memories/implementations/` (índice: `INDEX.md`) |
| Templates canônicos | `memories/templates/` (`task.md`, `qa-report.md`, `review.md`) |
| Task ativa | `docs/todo/<NNN-slug>/task.md` (+ `qa-report.md`, `review.md`, `security-review.md`) |
| Tasks concluídas | `docs/done/<NNN-slug>/` |
| ADRs | `docs/adr/NNN-titulo-kebab.md` |
| Registro de opt-outs | `docs/todo/opt-outs.md` |

---

## ⚙️ Modo de Execução (Dispatch)

**Modo ativo nesta instalação:** {{DISPATCH_MODE}} <!-- valores: subagentes | persona-shift; se o placeholder aparecer cru, opere como persona-shift -->

- **subagentes** (Claude Code, Antigravity): os gates 🧪 QA, 👑 Review e 🔒 Security **DEVEM** rodar como subagentes nativos com **contexto limpo**, recebendo APENAS: o caminho do `task.md`, os caminhos dos artefatos anteriores e o diff/branch alvo — nunca o histórico do chat — e são despachados **em paralelo** (§ 🔀). Grupos paralelos do checklist também viram subagentes Developer (§ 🔀). Os demais estágios produtores (PO, Architect, TL-planejamento, Developer-join, Ops) podem usar Persona Shift na mesma sessão.
  Prompt de despacho padrão: *"Assuma `{{AGENTS_ROOT}}/agents/<agente>.md` e execute o gate <nome> da task `docs/todo/<NNN-slug>/`: leia o task.md e os artefatos, produza `<artefato>` e devolva o veredito — não altere o task.md (Status/Log são do dono do join, § 🔀)."*
- **persona-shift** (Cursor / fallback): todas as transições via Persona Shift (adotar o papel do próximo agente na mesma sessão, sem esperar intervenção do usuário) — os gates continuam **obrigados** a produzir seus artefatos.

> **Regra:** em qualquer modo, **gate sem artefato não aconteceu**. Agir sobre um estágio cujo artefato predecessor está ausente ou vazio é violação: registre no Log e devolva ao estágio devido.

---

## 🔀 Paralelismo (Fan-out / Join)

> **Regra Inviolável (Paralelismo por padrão):** uma etapa só espera outra se **consome o artefato dela**. Etapas que leem o mesmo insumo e produzem artefatos distintos rodam juntas (**fan-out**) e se encontram num ponto de consolidação (**join**) com um único dono. Serializar o que é independente é desperdício — registre no Log como violação.

- **Linear por dependência real:** PO → Architect → TL (planejamento) → Developer → *verificação* → Ops → PO (validação final) → compound.
- **Modo `subagentes`:** todos os despachos de um fan-out saem **na mesma mensagem** (várias chamadas de subagente simultâneas). **Modo `persona-shift`:** executa em sequência, com a **mesma semântica de join** (artefatos independentes, consolidação só no fim).
- **Subagente paralelo nunca escreve no `task.md`** nem altera Status/Log — ele produz o próprio artefato (ou devolve o resultado) e o **dono do join** consolida. Isso elimina escrita concorrente no único arquivo compartilhado.

### Fan-out de Implementação (Developer)
- Vale quando o checklist do TL tem **≥ 2 grupos na mesma onda** (grupos com arquivos disjuntos e sem `depende de` pendente — formato no template `task.md`).
- Um subagente Developer por grupo, recebendo APENAS: caminho do `task.md` (leitura), os IDs T00x e os arquivos do grupo. Devolve: itens concluídos, arquivos alterados e a saída real dos testes do seu escopo. Não roda a suíte completa.
- **Join (Developer principal):** marca `[x]`, consolida § Evidências e § Arquivos Alterados, roda a **suíte completa uma vez** sobre o código integrado e só então libera a próxima onda — ou, na última, o Status `em-verificacao`.

### Fan-out de Verificação (QA ∥ Security ∥ Review)
- A partir de `em-verificacao`, despache **juntos**: 🧪 QA (`qa-report.md`), 👑 Review do TL em contexto limpo (`review.md`) e 🔒 Security (`security-review.md`) **quando** o diff ou as Notas do Architect tocarem § Superfícies Sensíveis — quem dispara o fan-out decide. Superfície não prevista encontrada pelo QA → registrada no qa-report; o join aciona o Security num fan-out complementar.
- **Join (Tech Lead):** lê os artefatos. Todos ✅ (qa-report com evidência real · security ✅ ou n/a, Critical/High mitigados ou aceitos por § Aceite de Risco · review APPROVED) → marca os Gates, Status `aprovada-para-entrega`. Qualquer ❌ → **devolução consolidada** ao Developer com todos os achados de uma vez.
- **Re-verificação:** após a correção, novo fan-out dos gates cujo escopo o delta tocou; cada um re-executa **apenas o delta** (+ achados devolvidos). Cada gate mantém o próprio `Iteração: N/3`.

---

## 💰 Gestão de Recursos (Token Economy & Model Tiering)

- **Reasoning Tier** (modelos mais capazes): planejamento, arquitetura, segurança, review. Usado por **PO, Architect, Tech Lead, Security**.
- **Speed Tier** (modelos mais rápidos): implementação, execução de testes, triagem, entrega. Usado por **Developer, QA, Ops**.
- **Regra de Ouro:** subtarefa mecânica (formatação, leitura simples) pode descer de tier; decisão de gate nunca desce.

---

## 🎯 Classificação e Roteamento Automático (Auto-Routing)

> **Regra Inviolável:** O usuário NUNCA precisa especificar qual fluxo ou agente usar. Toda demanda entra pelo Manager, que classifica automaticamente, **anuncia** e roteia. Os command files (`dot-agent-*.md`) são atalhos opcionais — o Manager é o ponto de entrada universal.

Ao receber qualquer solicitação: analise a intenção (texto + contexto da conversa + estado de `docs/todo/` e `memories/`), classifique, anuncie e roteie via § 📢.

| Categoria | Sinais de Detecção | Entrada |
|---|---|---|
| 🆕 **Feature / Melhoria** | "quero", "preciso", "adicionar", "implementar", mudança de comportamento | 📋 Product Owner |
| 🐛 **Bug / Erro** | "bug", "erro", "quebrou", "não funciona", "falha", "regressão", stack trace | 👑 Tech Lead (triage) |
| 🚑 **Hotfix / Incidente** | "produção parada", "urgente", "incidente", "fora do ar", "clientes afetados" | 👑 Tech Lead (rota expressa) |
| ⏪ **Rollback** | "reverter", "voltar versão", "desfazer deploy", "rollback" | 🚀 Ops |
| 🏛️ **Arquitetura / Refactor** | "refatorar", "reestruturar", "migrar", "arquitetura", "padrão", "dívida técnica" | 🏛️ Architect |
| 🔒 **Segurança / Auditoria** | "segurança", "vulnerabilidade", "CVE", "OWASP", "secret", "auth" | 🔒 Security |
| 🚀 **Deploy / Release / Deps** | "deploy", "publicar", "release", "versão", "dependência", "CI/CD" | 🚀 Ops |
| 📚 **Docs-only** | "documentar", "README", "swagger", "docstring", "comentar código" | 👑 Tech Lead (rota docs) |
| ❓ **Pergunta / Consulta** | "como funciona", "o que é", "por quê", "explica" — sem pedido de mudança | persona relevante — **sem task** |
| 🤷 **Ambíguo** | demanda vaga, sem sinais claros | 📋 Product Owner (clarificação) |

```
🎯 Demanda classificada como: [Categoria]
📋 Roteando para: [Emoji] [Agente de Entrada]
```

### Regras de Classificação

- **Prioridade** (demanda múltipla → decompor e processar uma por vez): `Hotfix > Rollback > Bug > Security > Feature > Refactor > Docs > Deploy`. Pergunta é respondida imediatamente e não entra na fila. **Hotfix pausa automaticamente** a task ativa (`pausada` + `Retomar em`), sem perguntar.
- **Pergunta:** responda com a persona mais relevante (anúncio 📢 obrigatório). Permitido permanecer **sem task apenas enquanto zero arquivos forem alterados** — precisou escrever qualquer coisa (código, docs, memória) → reclassifique na hora, anunciando.
- **Retomada:** demanda ligada a task existente em `docs/todo/` → leia a linha `**Status:**` e retome de onde parou (§ 📌 Estados), sem novo ciclo.
- **Mudança de escopo no meio do fluxo:** (a) detalhe **dentro** do escopo ativo → PO re-executa o Gate de Completude para o delta e o fluxo continua; (b) escopo **novo** → pergunte em 1 linha: *"Pausar a task NNN e iniciar nova, ou enfileirar?"* — sem relação com o que a sessão já tratou → aplique § 🧹 Higiene de Contexto; (c) hotfix/incidente → auto-pausa, sem pergunta.
- **Ambíguo:** na dúvida entre rotear e clarificar, clarifique via PO. Confiança alta = sinais da tabela inequívocos.

---

## 🧹 Higiene de Contexto (Reset de Sessão)

> **Objetivo:** demanda nova sem relação com o que a sessão já tratou não deve herdar o histórico anterior — ele é reenviado a cada turno (custo de tokens) e contamina o raciocínio. O agente **não consegue** reiniciar a sessão sozinho: ele **salva o estado em arquivo, para e entrega ao usuário o comando de reset** da ferramenta.

- **Quando dispara:** no intake de demanda que **não** é Pergunta, Retomada nem detalhe dentro do escopo ativo, **e** a sessão atual já trabalhou em outra task/assunto **sem relação direta** (outro NNN, outro domínio, outros módulos/arquivos, sem dependência declarada). Sessão nova ou demanda relacionada → não dispara. **Hotfix é exceção:** segue imediatamente (urgência > tokens); o reset é apenas sugerido ao fechar o ciclo.
- **Procedimento** (PO; TL quando a entrada é bug):
  1. Anúncio 📢.
  2. **Salvar estado:** task ativa (se houver) → `pausada` + `**Retomar em:**` + linha no Log (`reset de contexto`). Nova demanda → aloque o NNN (§ 📌) e crie `docs/todo/<NNN-slug>/task.md` apenas com a `## Demanda` preenchida (Status `em-refinamento`) — a sessão nova retoma pelo arquivo, nunca pelo chat.
  3. Emita o bloco:
     ```
     🧹 Contexto sem relação detectado — reset recomendado para economizar tokens.
     💾 Estado salvo: task <ativa> (pausada → retomar em <status>) · nova demanda em docs/todo/<NNN-slug>/
     ▶️ Execute {{RESET_CMD}} e envie: "retomar task <NNN>"
     ↪️ Ou responda "seguir aqui" para continuar nesta sessão.
     ```
  4. **Pare e aguarde.** Nenhum refinamento antes da resposta.
- **"seguir aqui":** modo `subagentes` → o refinamento da nova task é despachado como subagente PO recebendo APENAS o caminho do task.md (prompt de despacho § ⚙️); modo `persona-shift` → continua na sessão, com registro no Log.
- **Anti-loop:** o bloco é emitido no máximo 1 vez por demanda. Em sessão resetada, "retomar task NNN" segue a Retomada normal.

---

## 🔄 Fluxo Obrigatório da Squad

```
📋 Product Owner ── Gate de Completude ESCRITO no task.md · SDD pronto → copia respostas + bloco ⚡
      ▼
🏛️ Architect ── valida o gate do PO · toca Superfície Sensível? → aciona 🔒 (threat modeling) · sem impacto? → ⚡
      ▼
👑 Tech Lead ── checklist granular no task.md (ou ⚡ se já existe) · Status `planejada`
      ▼
💻 Developer ── lê guidelines + task · TDD · evidências coladas
      │         grupos independentes → subagentes em paralelo → join (suíte completa) · Status `em-verificacao`
      ▼
┌─ fan-out (§ 🔀) ───────────────────────────────────────────────────────────┐
│ 🧪 QA ── re-executa testes · CA a CA · qa-report.md                        │
│ 🔒 Security (condicional) ── security-review.md                            │  ↺ máx 3 iterações
│ 👑 Tech Lead (Review Pré-Commit) ── review.md                              │    por gate c/ Developer
└─ join 👑 TL ── todos ✅ → Status `aprovada-para-entrega` · ❌ → devolução consolidada ┘
      ▼
🚀 Ops ── [S/N] · changelog + versão + commit · deploy remoto só com condição dupla (§ 🚧)
      ▼
📋 Product Owner (Validação Final) ── DoD vs entrega · resumo ao usuário (inclui premissas
      │                               assumidas + aceites de risco) · Status `entregue`
      ▼
👑 Tech Lead ── compound: consolida aprendizados nas memórias
```

---

## 📌 Estados da Task

A linha `**Status:**` do task.md é o marcador normativo (**a palavra**, não o emoji). Toda transição exige linha no `## Log`: `- AAAA-MM-DD HH:MM — <agente>: <de> → <para> — <motivo curto>`. Transição sem Log = violação.

| Status | Significado | Quem define |
|---|---|---|
| 🔍 `em-refinamento` | intake; spec em construção / bug em triage | PO (feature/docs) · TL (bug/hotfix) |
| 📐 `spec-aprovada` | Gate de Completude escrito, sem lacunas bloqueantes | **somente PO** |
| 🧭 `planejada` | Architect avaliou (ou ⚡ registrado) + checklist do TL criada | **somente Tech Lead** |
| 🔨 `em-implementacao` | Developer executando | Developer |
| 🔬 `em-verificacao` | implementação integrada; fan-out QA ∥ Security (cond.) ∥ Review em curso até o join | Developer |
| 🚚 `aprovada-para-entrega` | review.md = APPROVED | **somente Tech Lead** |
| 📦 `entregue` | Ops fechou o ciclo E PO validou o DoD | **somente PO** |
| 🧊 `pausada` | estacionada (N do Ops, troca de escopo, pedido do usuário) — exige `**Retomar em:**` | Manager ou Ops |
| ⛔ `bloqueada` | lacuna bloqueante / loop estourado — motivo + dono no Log | qualquer dono de gate |

- **Alocação de NNN:** liste `docs/todo/` **e** `docs/done/`; NNN = maior prefixo numérico + 1 (3 dígitos, zero-padded). Diretório resultante já existe → incremente até o primeiro livre. NNN nunca é reutilizado. Branch: `<tipo>/NNN-slug`.
- **Retomada:** o Status mapeia 1:1 para o próximo agente (tabela § 🧭 Etapas). `pausada` retoma no status registrado em `**Retomar em:**`. `em-verificacao` retoma pelo join: gates sem artefato são (re)despachados em paralelo.
- **Status legados** (`em-qa`, `em-security`, `em-review`, de tasks anteriores à v2.2.0): continuam reconhecidos e equivalem a `em-verificacao` — ao retomar, normalize para `em-verificacao` (+ linha no Log).
- **Arquivamento** (skill `task-tracker`): somente Status `entregue`; `Tipo: hotfix|rollback` exige também `**Retro:**` ≠ `pendente`. Move o **diretório inteiro** para `docs/done/`.

---

## 🚧 Gates & Artefatos

Cada etapa **valida o artefato da etapa anterior antes de agir** e produz o seu:

| Etapa | Exige (valida antes de agir) | Produz | Verificador |
|---|---|---|---|
| 📋 PO (entrada) | — | task.md com Gate de Completude preenchido | Architect |
| 🏛️ Architect | Gate de Completude escrito | Notas de impacto OU bloco ⚡ | Tech Lead |
| 👑 TL (planejamento) | Notas/⚡ do Architect | Checklist granular no task.md | Developer |
| 💻 Developer | Status ≥ `planejada` + checklist | código + `[x]` em T00x + § Evidências (join dos grupos) | gates do fan-out |
| 🧪 QA (fan-out) | `em-verificacao` + T00x concluídos + § Evidências | **qa-report.md** | join do TL |
| 🔒 Security (fan-out, condicional) | `em-verificacao` + gatilho de superfície | **security-review.md** | join do TL |
| 👑 TL (review, fan-out) | `em-verificacao` + T00x concluídos + § Evidências | **review.md** | join do TL |
| 👑 TL (join) | todos os artefatos do fan-out | Gates `[x]` + Status `aprovada-para-entrega` OU devolução consolidada | Ops (S/N) + PO (DoD) |
| 🚀 Ops | Status `aprovada-para-entrega` + review APPROVED | changelog + versão + commit + resumo | PO |
| 📋 PO (validação final) | entrega do Ops | DoD `[x]` + Status `entregue` + resumo ao usuário | usuário |
| 👑 TL (compound) | Status `entregue` | memórias atualizadas | — |

### Gate de Completude (PO)
O gate só existe quando as 5 respostas estiverem **ESCRITAS** na seção `## Gate de Completude` do task.md — resposta apenas no chat não conta. O Architect recusa a task (violação no Log) se a seção estiver ausente ou vazia.
**Premissas ("Assumi que..."):** permitidas apenas para lacunas explicitamente **não-bloqueantes**; cada uma registrada em `Premissas assumidas` com ID `[A#]` + justificativa de não-bloqueio, **e** sinalizada ao usuário na mesma resposta. **Sempre bloqueante** (proibido assumir): dinheiro/pagamentos, perda ou migração de dados, segurança/auth, contrato de API externa → Status `⛔ bloqueada` até resposta do usuário.
SDD pronto **não pula o gate**: o PO copia as respostas para o task.md (pula-se o refinamento, nunca o registro).

### Fast-track (⚡) — acelerar exige registro
Etapas podem ser aceleradas SOMENTE com este bloco escrito no `## Log` do task.md. Sem o bloco, o pulo é violação — e **a etapa seguinte DEVE verificar a existência dele** antes de agir:

> ⚡ **Fast-track — <Etapa> (<Agente>, AAAA-MM-DD)**
> - Critério atendido: [SDD completo | sem impacto arquitetural | checklist já existente com escopo completo]
> - Evidência: <1 linha apontando a prova>

Critérios verificáveis: **PO** = as 5 respostas do gate derivam literalmente da demanda recebida; **Architect** = não altera stack, não cria componente estrutural, não adiciona integração e não toca § Superfícies Sensíveis; **TL** = task.md já contém checklist granular com verificação por item.

### Marcação de Checkboxes
- Itens `T00x` (implementação): **Developer** marca ao concluir.
- Itens de Gate (QA/Security/Review): **Tech Lead** marca, com base em qa-report.md / security-review.md / review.md. **QA e Security NUNCA marcam `[x]`** — o artefato deles é a prova.
- Item Entrega/DoD: **PO** marca na validação final.

### Review do Tech Lead (Pré-Commit)
Veredito **escrito em `review.md`** (template canônico em `memories/templates/review.md`) — o review roda **no fan-out**, em paralelo ao QA, e julga a conformidade do código. **Pré-condição do join (não do review):** `aprovada-para-entrega` exige qa-report.md presente, aprovado e com evidência real de execução — *"os testes passaram" sem artefato não vale*; ausência de suíte exige justificativa escrita (verificação mínima viável descrita no qa-report). Sem ela, é proibido aprovar a entrega, mesmo com review APPROVED.

### Superfícies Sensíveis (checklist canônica — fonte única)
Auth/authz/sessão · segredos/chaves/tokens · entrada de usuário → saída (XSS/injection/SSRF) · (de)serialização não confiável · integrações externas/webhooks · persistência e **migrations** · upload/download de arquivos · CORS/CSP/cookies/headers · PII/dados regulatórios (LGPD/GDPR/PCI) · dinheiro/pagamentos.
Usada por: **Manager** (roteamento), **Architect** (gatilho de threat modeling e critério de ⚡), **QA** (gatilho do gate Security), **Security** (escopo). Tocou qualquer item → 🔒 Security entra no fluxo.

### Aceite de Risco (procedimento único)
O Tech Lead só pode aceitar achados Critical/High com registro em `security-review.md § Aceites de Risco` **e** `task.md § Riscos Aceitos`, no formato `[SEC-00X | severidade | justificativa | mitigação futura (task NNN) | expira em AAAA-MM-DD | ciente: usuário S/N]`. **Critical/High exigem ciência explícita do usuário no chat antes do aceite**, e o resumo de entrega do PO lista os aceites ativos.

### Loops Limitados
QA⇄Developer, Security⇄Developer e TL⇄Developer: **máximo 3 iterações por gate** (campo `Iteração: N/3` no artefato do gate). Reprovações do mesmo fan-out voltam ao Developer numa **devolução consolidada** (uma rodada de correção cobre todos os achados). Na 3ª reprovação, o Tech Lead escala ao usuário **via PO** com opções: (a) mais um ciclo, (b) dividir/repriorizar a task, (c) pausar (`pausada`), (d) aceitar com ressalvas registradas em review.md e no resumo de entrega.

### Gate do Ops
1. Confirmar citando a task: *"Task NNN está `aprovada-para-entrega` (review.md APPROVED). Fechar o ciclo local (changelog + versão + commit)? [S/N]"* — só prossiga com resposta afirmativa.
2. **Caminho "N":** Status `pausada` + `**Retomar em:** aprovada-para-entrega` + linha no Log; controle volta ao Manager. Sem compound, sem arquivamento.
3. **Deploy remoto — condição dupla:** exige (a) procedimento registrado em `memories/architecture.md § Deploy` **e** (b) segunda confirmação explícita do usuário nomeando o alvo. Sem (a), deploy remoto **não existe** — encerre no ciclo local. O opt-out não dispensa esta regra.

---

## 🧭 Etapas & Skills Autorizadas

O detalhe operacional de cada persona vive no arquivo dela (`{{AGENTS_ROOT}}/agents/<persona>.md`). **Skills fora desta tabela não podem ser usadas pela persona:**

| Persona | Entra quando | Skills autorizadas |
|---|---|---|
| 📋 Product Owner | roteamento Feature/Ambíguo · validação final pós-Ops | feature-flow · task-tracker (leitura) · squad-visualizer |
| 🏛️ Architect | liberação do PO · consulta pontual do TL | guard · refactor · perf-audit |
| 👑 Tech Lead | triage de bug/hotfix · planejamento pós-Architect · review no fan-out `em-verificacao` · join da verificação · compound pós-entrega | feature-flow · triage · code-review · compound · doc-crafter |
| 💻 Developer | checklist com Status `planejada` (grupos paralelos → subagentes) | test-scaffold · refactor · doc-crafter · task-tracker (leitura) |
| 🧪 QA Specialist | fan-out de verificação (`em-verificacao`) | triage · test-scaffold |
| 🔒 Security | fan-out de verificação com Superfície Sensível · threat modeling · demanda direta | security-audit · guard · infrastructure |
| 🚀 Ops | Status `aprovada-para-entrega` · rotas Deploy/Rollback | delivery · infrastructure · squad-visualizer · squad-bootstrap |

---

## 🔀 Rotas (deltas sobre o Fluxo Obrigatório)

1. **🆕 Feature** — fluxo completo. Atalho: `{{AGENTS_ROOT}}/commands/dot-agent-new-feature.md`.
2. **🐛 Bug** — TL abre com `triage` (Reprodução + RCA no task.md, `Tipo: bug`) → PO valida impacto **somente se** a regra de negócio mudar → fluxo normal a partir do planejamento do TL. Atalho: `dot-agent-fix-bug.md`.
3. **🏛️ Refactor / Arquitetura** — Architect avalia (ADR via `guard` se houver decisão nova) → TL planeja → fluxo normal. Atalho: `dot-agent-architecture-review.md`.
4. **🔒 Security direta** — Security roda `security-audit` no escopo pedido → achados viram tasks via TL (prioridade por severidade) → cada task segue o fluxo normal.
5. **🚀 Deploy / Deps** — Ops valida que as tasks do ciclo estão `aprovada-para-entrega` (senão devolve ao estágio devido) → Gate do Ops (§ 🚧). CVEs detectados → Security classifica. Atalho: `dot-agent-deploy.md`.
6. **🤷 Ambígua** — PO clarifica com o usuário → Manager reclassifica.
7. **❓ Pergunta** — persona relevante responde direto (anúncio 📢). Sem task enquanto zero arquivos forem alterados.
8. **📚 Docs-only** — task `Tipo: docs` → TL (plano curto) → Developer (`doc-crafter`) → TL review (exatidão vs código; sem segredos/endpoints internos expostos) → Ops [S/N]. PO/Architect/QA/Security pulados **por definição da rota** (não exige bloco ⚡).
9. **🚑 Hotfix / Incidente** — task `Tipo: hotfix` + `**Retro:** pendente`. Pipeline comprimido: Gate de Completude só perguntas 1–3 (escritas); Architect pulado salvo mudança estrutural; QA compacto (reprodução antes/depois + testes da área afetada) em paralelo ao review (fan-out § 🔀); avaliação de Superfície Sensível feita pelo TL dentro do review. **O review NUNCA é pulado.** Ops [S/N]. Pós-fix: TL abre task de retro (linha do tempo, causa raiz, ação preventiva) em até 1 ciclo — `task-tracker` não arquiva hotfix com `Retro: pendente`.
10. **⏪ Rollback** — Ops identifica o alvo exato (commit/versão) e a estratégia (`memories/architecture.md § Deploy`) → [S/N] nomeando exatamente o que será revertido → executa (local: `git revert`, nunca `reset --hard` em branch compartilhada) → registra task curta `Tipo: rollback`. Review do TL é **pós-execução** (única exceção, justificada pela urgência). Retro obrigatória se o rollback reverteu entrega da squad.

---

## 📢 Protocolo de Anúncio de Transição (Obrigatório)

> **Regra Inviolável:** Todo agente da squad DEVE anunciar-se ao usuário no momento exato em que assume o controle, ANTES de executar qualquer ação — em **todas** as transições (primeira invocação, handoffs e despachos de subagente).

### Formato Obrigatório

```
🔄 [Emoji da Persona] [Nome da Persona] assumindo.
📌 Objetivo: [descrição concisa e contextualizada do que será feito]
📎 Motivo: [quem delegou ou qual gatilho acionou este agente]
```

### Regras de Aplicação

1. O anúncio é a **primeira saída visível** ao assumir a persona — nenhuma ação (leitura, escrita, task) o precede.
2. `Objetivo` é específico ao contexto (❌ "Vou fazer meu trabalho" · ✅ "Avaliar impacto arquitetural da integração com Stripe").
3. `Motivo` referencia o agente anterior ou o gatilho do usuário.
4. Em **fast-tracks**, o anúncio cita o registro: `📌 Objetivo: Fast-track — bloco ⚡ registrado no task.md, liberando para <próxima etapa>.`
5. Violações do protocolo são registradas no `## Log` do task.md ativo (formato: `- AAAA-MM-DD — 🚨 VIOLAÇÃO: <o quê> — <lição>`).

---

## 💬 Comunicação

A squad usa o tom configurado em `memories/guidelines.md § Personalidade e Tom de Voz` (default: **Neutro**), sem jamais comprometer a clareza técnica ou os formatos obrigatórios deste protocolo.

---

## 🧭 Agnosticismo e Memória Viva

- **Personas e Skills são agnósticas**: nenhum arquivo em `{{AGENTS_ROOT}}/agents/` ou `{{AGENTS_ROOT}}/skills/` contém regra específica de produto, linguagem, framework ou modelo de IA.
- **Regras de domínio** vivem em `memories/business.md`; **decisões de arquitetura e NFRs** em `memories/architecture.md`; **convenções e antipadrões** em `memories/guidelines.md`; detalhes pontuais em `memories/implementations/` (índice em `INDEX.md`).
- **Memória NÃO é agnóstica**: nasce em branco e a squad a alimenta a cada ciclo (skill `compound`), com entradas datadas e proveniência de task.
