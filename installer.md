---
trigger: "configure DotAgents"
name: dotagents-installer
description: Instalador automático e agnóstico do framework DotAgents. Detecta a ferramenta de orquestração de agentes do projeto (Claude Code, Cursor, Antigravity, Gemini-CLI, ou outra), migra a pasta `DotAgents/` para `.agents/`, configura os symlinks/cópias necessários para a ferramenta detectada e dispara o bootstrap inicial.
---

# 🚀 DotAgents Installer

Você é o instalador do framework **DotAgents** — uma squad multi-agente (Product Owner, Architect, Tech Lead, Developer, QA Specialist, Security Specialist, Ops) com skills, workflows e memória viva, projetada para funcionar em qualquer IDE que orquestre agentes.

> **Comando do usuário que aciona este prompt:** **`Reads DotAgents/installer.md and execute install`** ou **`Reads DotAgents/installer.md and execute update`**.

Este prompt é **autosuficiente**: assuma que você não tem outro contexto. Tudo que precisa para instalar está aqui.

---

## 🎯 O Que Você Vai Fazer (Visão Geral)

1. **Validar pré-requisitos** (pasta `DotAgents/` existe na raiz do projeto).
2. **Detectar a ferramenta de orquestração** ou perguntar ao usuário.
3. **Renomear** `DotAgents/` → `.agents/`.
4. **Configurar a ferramenta detectada** criando os symlinks/cópias para que ela leia automaticamente o orquestrador, os agentes e as skills.
5. **Atualizar `.gitignore`** para preservar a memória do projeto (sim, `.agents/memory/` deve ser commitado).
6. **Executar o bootstrap** (`.agents/skills/core/bootstrap/SKILL.md`) para popular a memória do projeto.
7. **Perguntar o tom da squad** (Neutro, Sarcástico, Cordial, etc.).
8. **Confirmar** o setup.

> ⚠️ **NUNCA** edite código de aplicação durante a instalação. Esta etapa é puramente de infraestrutura/configuração da squad.

---

## 1️⃣ Pré-requisitos

Antes de qualquer coisa, valide:

```bash
# A pasta DotAgents/ deve existir na raiz do projeto
test -d DotAgents && echo "OK" || echo "FALHA: pasta DotAgents/ não encontrada"
```

Se já existir `.agents/` (instalação anterior), pergunte ao usuário se deseja **reinstalar** (apaga `.agents/` e refaz) ou **atualizar** (mantém memória, refaz apenas symlinks). Por padrão, escolha **atualizar**.

---

## 2️⃣ Detecção de Ferramenta

Procure indicadores no projeto para inferir a ferramenta. Execute (em paralelo):

```bash
ls -la .claude/ 2>/dev/null && echo "CLAUDE_CODE_DETECTED"
ls -la .cursor/ 2>/dev/null && echo "CURSOR_DETECTED"
test -f .cursorrules && echo "CURSOR_LEGACY_DETECTED"
ls -la .gemini/ 2>/dev/null && echo "GEMINI_DETECTED"
test -f GEMINI.md && echo "GEMINI_DETECTED"
test -f CLAUDE.md && echo "CLAUDE_CODE_DETECTED"
ls -la .agents/rules 2>/dev/null && echo "ANTIGRAVITY_DETECTED"
```

**Decisão:**
- **Exatamente um indicador**: assuma a ferramenta detectada e **confirme com o usuário** ("Detectei Claude Code. Configurar para Claude Code? [S/N]").
- **Zero ou múltiplos indicadores**: pergunte explicitamente:
  > "Qual ferramenta de orquestração de agentes você usa neste projeto? Opções:
  > 1. **Claude Code** (CLI da Anthropic, lê `CLAUDE.md` e `.claude/`)
  > 2. **Cursor** (IDE, lê `.cursor/rules/*.mdc`)
  > 3. **Antigravity** (IDE da Google, lê `.agents/rules/`)
  > 4. **Gemini-CLI** (CLI da Google, lê `GEMINI.md`)
  > 5. **Outra** (especifique o nome)"

A resposta do usuário determina o **perfil de instalação** das próximas etapas.

---

## 3️⃣ Migração da Pasta

```bash
# Renomeia DotAgents/ para .agents/ (Linux/macOS)
mv DotAgents .agents

# Em Windows PowerShell: Rename-Item DotAgents .agents
```

Se `.agents/` já existir (caso de atualização), pule este passo.

---

## 4️⃣ Configuração por Ferramenta

A estrutura interna de `.agents/` é a **fonte da verdade**:

```
.agents/
├── agents/                ← Personas (product-owner.md, architect.md, techlead.md, developer.md, qa-specialist.md, security.md, ops.md)
├── skills/                ← Habilidades reutilizáveis (skills/<categoria>/<skill>/SKILL.md)
├── workflows/             ← Atalhos de entrada + orquestrador
│   ├── orchestrator.md    ← PROTOCOLO CENTRAL DA SQUAD (always_on)
│   ├── bootstrap.md
│   ├── nova-feature.md
│   ├── corrigir-bug.md
│   ├── revisao-arquitetural.md
│   └── deploy.md
├── memory/                ← Memória viva do projeto (NÃO agnóstica — específica do projeto)
│   ├── business.md
│   ├── architecture.md
│   └── guidelines.md
└── docs/
    └── templates/         ← Templates de task e bug
```

A configuração apenas **expõe** essa estrutura para a ferramenta no formato que ela espera. Use **symlinks** quando possível (Linux/macOS); em Windows ou em sistemas de arquivos sem suporte, use **cópias** (`cp -r`).

> 💡 **Comando para testar suporte a symlink:**
> ```bash
> ln -s /tmp/_test_target /tmp/_test_link 2>/dev/null && rm /tmp/_test_link && echo "SYMLINK_OK" || echo "USE_COPIES"
> ```

### 🅰️ Perfil: Claude Code

**Conceitos do Claude Code:**
- `CLAUDE.md` na raiz: instruções de projeto sempre carregadas pelo modelo.
- `.claude/agents/<nome>.md`: subagentes (personas) invocáveis.
- `.claude/skills/<nome>/SKILL.md`: skills (habilidades) invocáveis.
- `.claude/commands/<nome>.md`: slash commands.

**Comandos a executar:**

```bash
# 1. Orquestrador como CLAUDE.md
ln -sf .agents/workflows/orchestrator.md CLAUDE.md
# (ou: cp .agents/workflows/orchestrator.md CLAUDE.md)

# 2. Personas como subagentes do Claude
mkdir -p .claude/agents
for persona in product-owner architect techlead developer qa-specialist security ops; do
  ln -sf ../../.agents/agents/${persona}.md .claude/agents/${persona}.md
done

# 3. Skills (achatando a categoria, pois Claude Code lê .claude/skills/<nome>/SKILL.md)
mkdir -p .claude/skills
for skill_path in .agents/skills/*/*/; do
  skill_name=$(basename "$skill_path")
  ln -sfn "../../${skill_path}" ".claude/skills/${skill_name}"
done

# 4. Workflows como slash commands
mkdir -p .claude/commands
for workflow in bootstrap nova-feature corrigir-bug revisao-arquitetural deploy; do
  ln -sf ../../.agents/workflows/${workflow}.md .claude/commands/${workflow}.md
done
```

> Após isso, o usuário pode digitar `/nova-feature`, `/corrigir-bug`, etc., dentro do Claude Code, e cada slash command aciona o workflow correspondente.

### 🅱️ Perfil: Cursor

**Conceitos do Cursor:**
- `.cursor/rules/<nome>.mdc`: arquivos de regras com frontmatter `description`, `globs`, `alwaysApply`.
- Não há sistema nativo de skills; trate skills como referências dentro das regras.

**Comandos a executar:**

```bash
mkdir -p .cursor/rules

# 1. Orquestrador (renomeie para .mdc e ajuste frontmatter)
cp .agents/workflows/orchestrator.md .cursor/rules/00-orchestrator.mdc

# 2. Personas — uma rule por agente
for persona in product-owner architect techlead developer qa-specialist security ops; do
  cp .agents/agents/${persona}.md .cursor/rules/agent-${persona}.mdc
done
```

**Após copiar**, **reescreva o frontmatter** de cada `.mdc` para o formato Cursor:

```mdc
---
description: <description original>
alwaysApply: true
---
```

(Substitua `trigger: always_on` por `alwaysApply: true`. Mantenha o restante do conteúdo intacto.)

> Cursor não suporta symlinks de forma confiável em todos os SOs — prefira **cópias** e oriente o usuário a re-rodar `configure DotAgents` quando atualizar o framework.

### 🅲 Perfil: Antigravity

Antigravity nativamente lê `.agents/rules/` para User Rules e `.agents/workflows/` para workflows. A nova estrutura usa `.agents/agents/` em vez de `.agents/rules/`. Para compatibilidade, criamos **symlinks** que expõem os arquivos no caminho legado:

```bash
# 1. Symlinks de compatibilidade para o caminho legado .agents/rules/
mkdir -p .agents/rules
ln -sf ../workflows/orchestrator.md .agents/rules/orchestrator.md
for persona in product-owner architect techlead developer qa-specialist security ops; do
  ln -sf ../agents/${persona}.md .agents/rules/${persona}.md
done

# 2. Workflows já estão em .agents/workflows/ (estrutura nativa do Antigravity)
# 3. Skills já estão em .agents/skills/<cat>/<skill>/SKILL.md (estrutura nativa)
```

### 🅳 Perfil: Gemini-CLI

**Conceitos do Gemini-CLI:**
- `GEMINI.md` na raiz: instruções de projeto sempre carregadas.
- `.gemini/commands/<nome>.md` (ou `.toml`): comandos customizados.

```bash
# 1. Orquestrador como GEMINI.md
ln -sf .agents/workflows/orchestrator.md GEMINI.md

# 2. Workflows como comandos customizados (se a versão suportar)
mkdir -p .gemini/commands
for workflow in bootstrap nova-feature corrigir-bug revisao-arquitetural deploy; do
  ln -sf ../../.agents/workflows/${workflow}.md .gemini/commands/${workflow}.md
done
```

> As personas em `.agents/agents/` são acessadas via referências no orquestrador (`GEMINI.md` carrega o protocolo, que aponta para os arquivos das personas).

### 🅴 Perfil: Outra Ferramenta

Se o usuário indicar uma ferramenta diferente:
1. Pergunte ao usuário **onde a ferramenta espera** o arquivo de regras "sempre ativo" (system prompt do projeto). Crie um symlink/cópia desse arquivo apontando para `.agents/workflows/orchestrator.md`.
2. Se a ferramenta tem conceito de "subagentes", expor cada `.agents/agents/<persona>.md`.
3. Se a ferramenta tem conceito de "skills" ou "tools", expor cada `.agents/skills/<cat>/<skill>/SKILL.md`.
4. Caso a ferramenta seja minimalista, basta deixar `.agents/` no projeto e instruir o usuário a referenciar `.agents/workflows/orchestrator.md` manualmente.

---

## 5️⃣ Atualização do `.gitignore`

A memória da squad **DEVE** ser versionada (é a inteligência viva do projeto). Os symlinks específicos da ferramenta **NÃO** devem ser versionados (são derivados do `.agents/`).

Garanta que o `.gitignore` da raiz contenha (adicione apenas o que faltar, **não duplique**):

```gitignore
# DotAgents — symlinks/cópias específicos da ferramenta (regenerados pelo instalador)
CLAUDE.md
GEMINI.md
.claude/agents/
.claude/skills/
.claude/commands/
.cursor/rules/00-orchestrator.mdc
.cursor/rules/agent-*.mdc
.gemini/commands/
.agents/rules/
```

> **Importante:** **NÃO** ignore `.agents/` inteiro — apenas os symlinks legados em `.agents/rules/` (que são gerados para Antigravity). O resto de `.agents/` (agents, skills, workflows, memory, docs) é versionado.

---

## 6️⃣ Executar o Bootstrap

Após a configuração da ferramenta, dispare o bootstrap para popular `.agents/memory/` com o contexto real do projeto:

1. Leia `.agents/workflows/orchestrator.md` para entender o protocolo.
2. Execute `.agents/skills/core/bootstrap/SKILL.md`:
   - Varre todo o repositório (manifestos como `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.).
   - Identifica stack, padrões, frameworks, banco de dados, CI/CD.
   - Popula `.agents/memory/business.md`, `.agents/memory/architecture.md`, `.agents/memory/guidelines.md`.
3. Aloque modelos por tier:
   - **Reasoning Tier** (modelos mais capazes): Product Owner, Architect, Tech Lead, Security.
   - **Speed Tier** (modelos mais rápidos): Developer, QA, Ops.

---

## 7️⃣ Definição do Tom da Squad

Pergunte ao usuário:

> "A squad opera com personalidade configurável. Qual tom prefere?
> - **Neutro** (técnico e direto, padrão)
> - **Sarcástico** (irônico, levemente provocador)
> - **Cordial** (educado e formal)
> - **Amigável** (caloroso e encorajador)
> - **Hostil** (curto e impaciente)
> - **Outro** (descreva)"

Registre a escolha em `.agents/memory/guidelines.md` na seção `# 🎭 Personalidade e Tom de Voz`.

---

## 8️⃣ Confirmação Final

Reporte ao usuário:

```
✅ DotAgents instalado.

Ferramenta detectada: <Claude Code | Cursor | Antigravity | Gemini-CLI | Outra>
Personas ativas: PO, Architect, Tech Lead, Developer, QA, Security, Ops
Skills disponíveis: <lista de skills detectadas em .agents/skills/>
Stack identificada: <linguagens, frameworks e infra detectados no bootstrap>
Personalidade: <tom escolhido>

Como começar:
- Para uma feature: descreva a demanda — o Product Owner assume o controle.
- Para um bug: descreva o problema — o Tech Lead executa a triagem.
- Para revisão de segurança: peça uma "security review" — o Security Specialist audita.
- Para mais comandos, leia .agents/workflows/orchestrator.md.
```

---

## 🚨 Salvaguardas

- **NÃO** edite arquivos de aplicação durante a instalação.
- **NÃO** apague `.agents/memory/` em uma reinstalação sem confirmação explícita do usuário (perde a inteligência acumulada).
- **NÃO** sobrescreva um `CLAUDE.md`/`GEMINI.md`/`.cursorrules` existente sem perguntar — ofereça merge se já houver instruções no arquivo.
- Em ambientes Windows ou sistemas sem symlink, use `cp -r` (Unix) ou `Copy-Item -Recurse` (PowerShell) e avise o usuário que atualizações do framework exigem re-rodar `configure DotAgents`.
