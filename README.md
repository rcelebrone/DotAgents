# DotAgents — Squad Multi-Agente Agnóstica

Framework agnóstico para instalar uma **squad multi-agente** (PO, Architect, Tech Lead, Developer, QA, Security, Ops) em qualquer projeto, de qualquer linguagem. A squad é regida por um **Manager central** com roteamento automático, **gates por artefato verificável** (nenhuma etapa "aconteceu" sem o arquivo que a prova), estados de task auditáveis e uma **memória viva** específica do projeto.

**Versão:** 2.0.0 · **Ferramentas suportadas:** Antigravity (IDE e CLI) · Claude Code · Cursor AI

---

## 🚀 Instalação

Requisitos: `bash` e `git`. Opcional: `python3` ou `jq` (registro automático dos hooks de enforcement).

Clone o repositório (dentro ou fora do seu projeto):

```bash
git clone https://github.com/rodrigo-celebrone/DotAgents.git DotAgents
```

Rode o instalador **a partir da raiz do seu projeto** (ou aponte com `--dest`):

```bash
cd meu-projeto
bash ../DotAgents/install.sh --claude          # ou --antigravity, ou --cursor
```

| Flag | Efeito |
|---|---|
| `--antigravity` / `--claude` / `--cursor` | Escolhe a ferramenta (sem flag: menu interativo) |
| `--dest <dir>` | Projeto destino (default: diretório atual) |
| `--yes` | Sem confirmações (CI/automação) |
| `--no-hooks` | Não instala o hook de enforcement |
| `--cursor-native` | (Cursor) usa subagentes nativos em vez de Persona Shift |
| `--purge` | Remove a pasta `DotAgents/` ao final (default: **preserva**, para updates) |

O instalador é **idempotente**: re-rodar atualiza os artefatos da squad, preserva a memória viva e nunca sobrescreve seu `CLAUDE.md`/`AGENTS.md` — ele mantém apenas um **bloco gerido** entre os marcadores `<!-- dotagents:begin -->` e `<!-- dotagents:end -->`. Instalações v1 com symlink são convertidas automaticamente.

### O que é instalado, por ferramenta

| | Antigravity | Claude Code | Cursor |
|---|---|---|---|
| Artefatos | `.agents/{agents,skills,commands}` | `.claude/{agents,skills,commands}` | `.cursor/{agents,skills,commands}` + regra sempre-ativa em `.cursor/rules/` |
| Roteamento raiz | bloco gerido em `AGENTS.md` | bloco gerido em `CLAUDE.md` (com import `@.claude/commands/manager.md`) | bloco gerido em `AGENTS.md` |
| Subagentes | nativos (`subagent: true`) | nativos (`.claude/agents/`) | Persona Shift (ou nativos com `--cursor-native`) |
| Enforcement | `.agents/hooks.json` | `.claude/settings.json` (PreToolUse) | `.cursor/hooks.json` |
| Memória viva | `memories/` na raiz do projeto (compartilhada entre ferramentas) | idem | idem |

O frontmatter dos agentes é **traduzido na instalação** para o formato de cada ferramenta (nomes de tools, valores de `model`) — os arquivos-fonte permanecem agnósticos.

---

## 🧭 Primeiro passo após instalar: o Bootstrap

- **Claude Code:** rode `/dot-agent-bootstrap`
- **Antigravity:** peça — *"Execute as instruções de `.agents/commands/dot-agent-bootstrap.md`"*
- **Cursor:** peça — *"Execute as instruções de `.cursor/commands/dot-agent-bootstrap.md`"*

O bootstrap varre o projeto e popula as memórias (`memories/business.md`, `architecture.md`, `guidelines.md`). A partir daí, **qualquer demanda** é classificada e roteada automaticamente pelo Manager — você não precisa escolher agente nem fluxo.

---

## ⚙️ Como o fluxo funciona

```
Demanda → 🧠 Manager (classifica e roteia)
  → 📋 PO (Gate de Completude ESCRITO na task)
  → 🏛️ Architect (impacto/ADR; aciona 🔒 p/ superfícies sensíveis)
  → 👑 Tech Lead (checklist granular)
  → 💻 Developer (TDD + evidências coladas)
  → 🧪 QA (re-executa tudo → qa-report.md)         ↺ loops máx 3
  → 🔒 Security quando aplicável (security-review.md)
  → 👑 Review pré-commit (review.md, exige evidência de teste)
  → 🚀 Ops ([S/N] → changelog + versão + commit; deploy remoto só se configurado)
  → 📋 PO valida o DoD e entrega o resumo → memória atualizada (compound)
```

- **Gates por artefato:** cada etapa valida o artefato da anterior — *gate sem artefato não aconteceu*.
- **Estados auditáveis:** a task vive em `docs/todo/<NNN-slug>/task.md` com `Status` normativo e Log de transições; concluídas vão para `docs/done/`.
- **Rotas dedicadas:** Pergunta (sem task), Docs-only, **Hotfix** (expresso, com retro obrigatória), **Rollback** (git revert, nunca reset --hard) — além de Feature/Bug/Refactor/Security/Deploy.
- **Comandos-atalho:** `/dot-agent-new-feature`, `/dot-agent-fix-bug`, `/dot-agent-architecture-review`, `/dot-agent-deploy` — todos entram no mesmo pipeline (nenhum pula gates).

## 🔒 Enforcement

Duas camadas:
1. **Protocolo por artefatos** (agnóstica): specs, relatórios de QA, review e security são arquivos verificáveis; o Manager exige cada um no seu gate.
2. **Hook nativo** (`dotagents-gate.sh`, fail-open): nega edição de **código** quando não existe task ativa em `docs/todo/` — docs, memórias e configs da squad nunca são bloqueados.

**Opt-out consciente:** diga literalmente **"sem squad"** ou **"modo direto"** — vale só para a demanda atual, é registrado em `docs/todo/opt-outs.md` e nunca autoriza deploy remoto.

---

## 🏗️ A Squad

| Persona | Responsabilidade |
|---|---|
| 📋 **Product Owner** | Gate de Completude, user stories + critérios de aceite (Dado/Quando/Então), validação final do DoD. |
| 🏛️ **Architect** | Integridade sistêmica, NFRs, ADRs. Não escreve código de produção. |
| 👑 **Tech Lead** | Planejamento granular, triage de bugs, review pré-commit (review.md), memória via compound. |
| 💻 **Developer** | Implementação Clean Code + TDD com evidências. Não faz commit (Ops é o dono). |
| 🧪 **QA Specialist** | Re-executa a suíte, valida CA por CA, produz qa-report.md. Não corrige código. |
| 🔒 **Security Specialist** | Threat modeling, auditoria OWASP/CWE, rubrica de severidade, runbook de segredos. |
| 🚀 **Ops** | Ciclo de entrega local, smoke pós-deploy, rollback, fronteira do deploy remoto. |

## 📁 Estrutura pós-instalação

- `<raiz-da-ferramenta>/agents/` — personas · `skills/` — habilidades executáveis · `commands/` — Manager e atalhos · `hooks/` — gate de enforcement
- `memories/` (raiz do projeto) — memória viva (business, architecture, guidelines, implementations/ + templates canônicos)
- `docs/todo/` e `docs/done/` — tasks com artefatos de gate · `docs/adr/` — decisões arquiteturais

## 🔄 Atualização e desinstalação

- **Atualizar:** `git pull` na pasta `DotAgents/` + re-rodar o `install.sh` (idempotente; memórias preservadas).
- **Desinstalar:** remova o diretório da ferramenta (`.claude/`, `.agents/` ou `.cursor/`), o bloco entre `<!-- dotagents:begin -->` e `<!-- dotagents:end -->` no arquivo raiz, e — se desejar — `memories/` e `docs/todo|done/`.

## 📄 Licença

Consulte [`license.md`](license.md).
