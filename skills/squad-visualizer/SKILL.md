---
name: squad-visualizer
description: Apresenta o ecossistema completo do DotAgents — personas, fluxo paralelo (fan-out/join), hooks, guardrails determinísticos (Harness), estado das tasks e o Cérebro Sináptico de Memórias (grafo visual de nós e suas conexões) — em markdown com diagramas Mermaid gerados dos arquivos reais da instalação. Use para "apresentar a squad", "quem são vocês", "mostrar o cérebro de memórias", "visualizar ecossistema" ou "mostrar o fluxo".
---

# Skill: Squad Visualizer (Ecossistema Completo & Cérebro de Memórias)

Gera uma radiografia visual completa em **texto/markdown + diagramas Mermaid** de toda a instalação ativa da squad e do cérebro de memórias do projeto — funciona em qualquer CLI ou IDE, sem servidor e sem HTML.

## Workflow de Execução (6 Visões Obrigatórias)

Ao ser acionada, inspecione **os arquivos reais instalados no momento** (nunca responda de cor) e gere um painel estruturado contendo as 6 seções abaixo:

### 1. Coleta Dinâmica do Ecossistema Real
Leia diretamente do repositório antes de montar a saída:
- **Configuração da instalação:** `{{AGENTS_ROOT}}/.dotagents-version` (se existir) + `{{AGENTS_ROOT}}/commands/manager.md` (modo de execução `subagentes` vs `persona-shift`, rotas, higiene de contexto, estados).
- **Personas (7 agentes):** `{{AGENTS_ROOT}}/agents/*.md` (nome, missão, tier de modelo e skills autorizadas).
- **Skills (21 skills) e Hooks:** diretórios em `{{AGENTS_ROOT}}/skills/*/SKILL.md` e scripts em `{{AGENTS_ROOT}}/hooks/*.sh`.
- **Cérebro de Memórias (`memories/`):**
  - Hubs raiz: `memories/business.md`, `memories/architecture.md`, `memories/guidelines.md` (incluindo o Tom de Voz ativo).
  - Mapa Sináptico: `memories/implementations/INDEX.md` + leitura dos **Headers Semânticos YAML (`linhas 1–20`)** de todos os nós `memories/implementations/*.md` (`id`, `type`, `domain`, `summary`, `connections`, `harness`).
- **Tasks e ADRs:** `docs/todo/*/task.md`, `docs/done/*/` e `docs/adr/*.md` (se existirem).

---

### 2. Seção 1 — Cabeçalho de Status do Ecossistema
Apresente um resumo executivo da instalação:
- **Versão / Ferramenta Alvo / Modo de Dispatch** (`subagentes` ou `persona-shift`) · **Tom de Voz ativo** (lido de `memories/guidelines.md`).
- **Camadas de Enforcement Ativas:**
  1. Bloco raiz gerido (`CLAUDE.md` / `AGENTS.md`);
  2. Hooks instalados (`dotagents-remind.sh` — reinjeção de protocolo por prompt; `dotagents-gate.sh` — bloqueio de escrita sem task ativa; `dotagents-commit-check.sh` — regex de Conventional Commits);
  3. Higiene de Contexto (`manager § 🧹` — reset de sessão entre tarefas sem relação).

---

### 3. Seção 2 — Matriz da Squad (Personas, Tiers & 21 Skills)
Monte a tabela real das 7 personas com base em `{{AGENTS_ROOT}}/commands/manager.md § 🧭`:
- Colunas: `Persona` | `Emoji` | `Tier (Reasoning / Speed)` | `Missão (1 linha)` | `Gates que Controla` | `Skills Autorizadas`.
- Destaque separadamente os **6 Guardrails Determinísticos (Portões Duros Pré-Probabilísticos)**:
  - `linter-enforcer` (Gate Sintático CLI)
  - `coverage-gate` (Gate Matemático de Cobertura + `test-scaffold`)
  - `ast-validator` (Parser Estrutural AST / Anti-alucinação)
  - `dependency-lock` (Trava de Manifestos/Lockfiles e Auditoria CVE)
  - `semantic-commit-checker` (Validação RegEx de Commits)
  - `state-checkpoint` (Snapshot Git e Auto-Rollback)

---

### 4. Seção 3 — Diagrama do Fluxo Operacional Completo (Mermaid)
Gere um `flowchart TD` refletindo fielmente a arquitetura v2.2+ do Manager:
- Entrada e Auto-Routing (10 categorias: Feature, Bug, Hotfix, Rollback, Refactor, Security, Deploy, Docs, Pergunta, Ambíguo) + Higiene de Contexto (`🧹 Reset`).
- Pipeline Linear Inicial: `📋 PO (Gate de Completude)` → `🏛️ Architect (NFRs / ADR / ⚡)` → `👑 Tech Lead (Checklist Granular por Ondas)`.
- **Fan-out de Implementação:** `💻 Developer` com subgrafo paralelo de Grupos Independentes (`Grupo G1 ∥ Grupo G2`) → `Join do Developer` (`state-checkpoint` + suíte completa).
- **Portões Determinísticos Pré-Review:** `linter-enforcer` + `ast-validator`.
- **Fan-out de Verificação Paralela:** subgrafo `{ 🧪 QA (qa-report.md + coverage-gate) ∥ 🔒 Security (security-review.md + dependency-lock) ∥ 👑 TL Review (review.md) }` com loops limitados (`↺ máx 3 iterações`) → `Join do Tech Lead`.
- **Fechamento & Compounding Engineering:** `🚀 Ops ([S/N] + delivery + commit-check)` → `📋 PO (Validação Final + Aprovação de Melhorias)` → `👑 Tech Lead (Skill Compound: Harness Determinístico + Nós de Memória Sináptica + Branch/PR)`.

---

### 5. Seção 4 — 🧠 O Cérebro Sináptico de Memórias (Grafo Neural em Mermaid)
Esta seção visualiza a memória viva do projeto como um **cérebro de nós interconectados**, lendo os headers YAML de `memories/implementations/*.md` e os 3 hubs raiz:

1. **Diagrama Mermaid do Cérebro (`flowchart LR` ou `flowchart TD`):**
   - Crie o nó central `BRAIN(("🧠 Cérebro DotAgents\n(INDEX.md)"))` conectado aos 3 hemisférios/hubs raiz:
     - `BUS["📋 business.md\n(Regras Core)"]`
     - `ARCH["🏛️ architecture.md\n(Stack, NFRs & Deploy)"]`
     - `GUIDE["📏 guidelines.md\n(Convenções & Estilo)"]`
   - Para **cada arquivo** existente em `memories/implementations/*.md` (exceto `INDEX.md`):
     - Extraia do YAML frontmatter: `id`, `type`, `domain`, `summary`, `connections` e `harness`.
     - Crie um nó no diagrama com o nome do arquivo e o domínio/tipo, ligando-o ao seu hemisfério (`business`, `architecture` ou `guideline`).
     - Para cada item em `connections:`, desenhe uma **aresta sináptica rotulada** (`<-->|"relation"|` ou `-->|"relation"|`) ligando o nó de origem ao nó `target`!
     - Se o nó possuir um `harness` determinístico vinculado, exiba um indicador `🔒` no nó (ou sub-nó conectado) mostrando qual guardrail protege aquele conhecimento.
   - *Caso `memories/implementations/` ainda não possua nós criados no projeto:* renderize os 3 hemisférios raiz reais e exiba um subgrafo ilustrativo pontilhado (`"Exemplo de Sinapses que o Compound criará"`: ex. `payment-button.md` ↔ `stripe-webhook.md` ↔ `currency-format.md`) explicando que o cérebro ganhará novas sinapses a cada ciclo fechado pela skill `compound`.

2. **Catálogo Sináptico (Tabela de Headers sem precisar abrir os arquivos):**
   - Liste todos os nós de `memories/implementations/*.md` com:
     `Nó (Arquivo)` | `Hemisfério (type)` | `O que explica (summary)` | `Quando a IA deve ler (when_to_read)` | `Conexões Sinápticas (↔)` | `Guardrail / Harness (🔒)`.

---

### 6. Seção 5 — Radar de Tasks, ADRs e Harness Atual
- **Tasks (`docs/todo/` e `docs/done/`):** contagens e lista resumida de tasks ativas por `Status` (reutilizando a lógica de leitura da skill `task-tracker`, sem mover arquivos) e últimas tasks entregues.
- **ADRs (`docs/adr/`):** lista de decisões arquiteturais registradas e seus status.

---

## Entrega
- Responda diretamente no chat com o markdown completo e os diagramas Mermaid renderizáveis.
- Se o usuário solicitar persistência em arquivo, salve em `docs/squad-overview.md`.

## Restrições
- **Zero Servidor / Zero HTML:** toda visualização usa exclusivamente Markdown + Mermaid compatível com GitHub/CLI/IDEs.
- **Fidelidade Dinâmica:** nunca invente nós de memória como se já existissem no projeto sem marcá-los claramente como exemplo quando `memories/implementations/` estiver vazio; quando houver arquivos reais, extraia 100% dos nós e conexões dos headers YAML reais.
- **Economia de Tokens na própria execução:** para montar o Cérebro de Memórias, leia apenas `INDEX.md` e as primeiras 25 linhas (Header Semântico YAML) de cada arquivo em `memories/implementations/*.md`, sem carregar o corpo inteiro de dezenas de memórias.
