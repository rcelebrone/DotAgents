# DotAgents — Multi-Agent Orchestration Boilerplate

Template agnóstico para instalar uma squad multi-agente (PO, Architect, Tech Lead, Developer, QA, Security, Ops) em qualquer projeto que use uma ferramenta de orquestração de agentes — **Claude Code, Cursor, Antigravity, Gemini-CLI** ou outras.

A squad é regida por um **orquestrador central** (`workflows/orchestrator.md`), tem **personas** com responsabilidades claras (`agents/`), **skills** reutilizáveis (`skills/`) e uma **memória viva** específica do projeto (`memory/`).

---

## 🚀 Instalação em 1 comando

Dentro do projeto onde você quer instalar a squad, clone este repositório como `DotAgents/`:

```bash
git clone https://github.com/<owner>/DotAgents.git DotAgents
```

Em seguida, abra a sua IDE/CLI de orquestração de agentes (Claude Code, Cursor, Antigravity, Gemini-CLI, etc.) e digite:

> **`configure DotAgents`**

O agente ativo lerá `DotAgents/agent.md`, detectará automaticamente sua ferramenta de orquestração (perguntando se houver ambiguidade), renomeará a pasta para `.agents/`, criará os symlinks/cópias necessários para a ferramenta detectada, executará o bootstrap (varredura do projeto + popular memória) e perguntará o tom de comunicação da squad.

> **A squad estará pronta para receber demandas em menos de 1 minuto.**

---

## 🏗️ A Squad

| Persona | Responsabilidade | Tier |
|---|---|---|
| 🎯 **Product Owner** | Refina regras de negócio, define DoD, ponto de entrada de features. | Reasoning |
| 🏛️ **Architect** | Integridade sistêmica, ADRs, decisões em `architecture.md`. | Reasoning |
| 👑 **Tech Lead** | Triagem técnica, criação de tasks, coordenação ágil. | Reasoning |
| 💻 **Developer** | Implementação Clean Code + TDD a partir de `docs/todo/`. | Speed |
| 🧪 **QA Specialist** | Validação funcional, RCA de bugs, auditoria contra DoD. | Speed |
| 🔒 **Security Specialist** | AppSec/DevSecOps. Threat modeling, OWASP/CWE audit, secret scanning, validação de controles. | Reasoning |
| 🚀 **Ops** | Ciclo de entrega local (changelog, versão, commit) + deploy se configurado. | Speed |

---

## 📁 Estrutura

```
DotAgents/                          ← Este boilerplate (após instalação vira .agents/)
├── agent.md                        ← Instalador autosuficiente (acionado por "configure DotAgents")
├── README.md                       ← Este arquivo
│
├── agents/                         ← Personas da squad (uma por arquivo)
│   ├── product-owner.md
│   ├── architect.md
│   ├── techlead.md
│   ├── developer.md
│   ├── qa-specialist.md
│   ├── security.md
│   └── ops.md
│
├── skills/                         ← Habilidades reutilizáveis pelas personas
│   ├── core/
│   │   ├── bootstrap/SKILL.md      ← Varredura inicial e popular memória
│   │   └── compound/SKILL.md       ← Atualização de memória pós-merge
│   ├── sdlc/
│   │   ├── feature-flow/SKILL.md   ← Criar features e tasks
│   │   ├── delivery/SKILL.md       ← Build, versão, changelog
│   │   ├── refactor/SKILL.md       ← Refatoração segura
│   │   └── task-tracker/SKILL.md   ← Gerenciar docs/todo → docs/done
│   ├── quality/
│   │   ├── triage/SKILL.md         ← Triagem e RCA de bugs
│   │   ├── guard/SKILL.md          ← ADRs e conformidade arquitetural
│   │   └── security-audit/SKILL.md ← OWASP/CWE, secret scanning, threat modeling
│   └── ops/
│       ├── infrastructure/SKILL.md ← Auditoria de deps, CVEs, infra
│       └── squad-visualizer/SKILL.md ← Dashboard visual da squad
│
├── workflows/                      ← Orquestrador + atalhos de entrada
│   ├── orchestrator.md             ← PROTOCOLO CENTRAL (always_on)
│   ├── bootstrap.md                ← Setup inicial
│   ├── nova-feature.md             ← Iniciar feature
│   ├── corrigir-bug.md             ← Iniciar correção
│   ├── revisao-arquitetural.md     ← Revisão arquitetural
│   └── deploy.md                   ← Release/deploy
│
├── memory/                         ← Memória viva do projeto (NÃO agnóstica)
│   ├── business.md                 ← Regras de negócio (governa: PO)
│   ├── architecture.md             ← Decisões arquiteturais e NFRs (governa: Architect + Security)
│   └── guidelines.md               ← Padrões de código + tom da squad (governa: todos)
│
└── docs/
    ├── templates/
    │   ├── task.md                 ← Template de task
    │   └── bug.md                  ← Template de bug
    ├── todo/                       ← Tasks em andamento (criadas durante o desenvolvimento)
    └── done/                       ← Tasks concluídas (arquivadas pelo task-tracker)
```

---

## 🛠️ Como a Ferramenta é Detectada

O instalador (`agent.md`) procura indicadores no projeto:

| Ferramenta | Indicador | Configuração aplicada |
|---|---|---|
| **Claude Code** | `.claude/`, `CLAUDE.md` | Symlinks: `CLAUDE.md` ← orchestrator, `.claude/agents/` ← personas, `.claude/skills/` ← skills, `.claude/commands/` ← workflows |
| **Cursor** | `.cursor/`, `.cursorrules` | Cópias `.mdc` em `.cursor/rules/` (orchestrator + cada persona) com frontmatter `alwaysApply: true` |
| **Antigravity** | `.agents/rules/` | Estrutura nativa + symlinks de compatibilidade em `.agents/rules/` |
| **Gemini-CLI** | `GEMINI.md`, `.gemini/` | Symlink `GEMINI.md` ← orchestrator + workflows como `.gemini/commands/` |
| **Outra** | (perguntado ao usuário) | Configuração manual conforme convenção da ferramenta |

Se nenhum indicador for detectado (ou houver mais de um), o instalador **pergunta** a ferramenta.

---

## 🔄 Fluxo da Squad

```
📋 Product Owner → 🏛️ Architect → 👑 Tech Lead → 💻 Developer → 🧪 QA → (🔒 Security se aplicável) → 🚀 Ops
```

**Regras-chave:**
- **Fast-track**: cada persona avalia se a etapa pode ser pulada (PO pula refinamento se SDD chega pronto; Architect pula ADR se não há mudança estrutural; Tech Lead pula criação de task se ela já existe).
- **Security é acionado** quando o código toca superfícies sensíveis (auth, dados/PII, segredos, integrações externas, upload, persistência) ou explicitamente pelo Tech Lead/Architect/usuário.
- **A squad nunca é pulada** sem solicitação explícita do usuário ("execute por fora da squad").

Veja o protocolo completo em `workflows/orchestrator.md`.

---

## 🧠 Memória Viva (Não Agnóstica)

`memory/business.md`, `memory/architecture.md` e `memory/guidelines.md` começam praticamente vazios em uma instalação nova. Eles **devem** ser populados pelo bootstrap (varredura inicial) e mantidos pela squad ao longo do desenvolvimento.

| Arquivo | O que vive ali | Quem mantém |
|---|---|---|
| `business.md` | Regras de negócio, terminologia de domínio, fluxos de permissão | PO |
| `architecture.md` | Stack, NFRs, decisões arquiteturais, modelo de ameaças, controles de segurança ativos | Architect + Security |
| `guidelines.md` | Padrões de código, antipadrões, lint, vulnerabilidades remediadas, **tom da squad** | Todos (atualizado por `compound/SKILL.md` ao final dos ciclos) |

---

## 🔒 Segurança Shift-Left

O **Security Specialist** atua em três momentos:

1. **Threat Modeling (Architect aciona)** — antes da implementação, quando a feature toca superfícies sensíveis.
2. **Code Audit (QA aciona)** — após o Developer entregar, quando o código modifica auth/dados/integrações/upload/PII.
3. **Security Review (Tech Lead/usuário aciona)** — revisão dedicada sob demanda.

A skill `skills/quality/security-audit/SKILL.md` aplica **OWASP Top 10**, **CWE Top 25**, **secret scanning** e **CVE audit** (em colaboração com Ops).

---

## 🌍 Agnosticismo

- **Personas e Skills** são **agnósticos** a stack/produto — nenhum arquivo em `agents/` ou `skills/` deve conter regra específica de um framework, linguagem ou domínio.
- **Memória** **não é** agnóstica — é específica do projeto onde a squad foi instalada. Bootstrap a inicializa, a squad a mantém viva.

---

## 📦 Reinstalar / Atualizar

Para atualizar o framework:
```bash
cd /seu/projeto
rm -rf DotAgents && git clone https://github.com/<owner>/DotAgents.git DotAgents
```
Em seguida digite `configure DotAgents` na ferramenta. O instalador detecta a presença prévia de `.agents/` e oferece **atualizar** (mantém memória) ou **reinstalar do zero** (apaga memória — perde a inteligência acumulada do projeto).

---

## 📄 Licença

**Uso não comercial.** Este framework é livre para uso pessoal, acadêmico, educacional e em organizações sem fins lucrativos. **Comercialização — direta ou indireta — é estritamente proibida** sem licença prévia por escrito.

Leia os termos completos em [`license.md`](license.md) antes de usar, modificar ou redistribuir. Para licenciamento comercial, contate o detentor do copyright indicado no arquivo.
