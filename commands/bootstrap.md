---
description: Setup e calibração da squad — instala os componentes, configura a ferramenta de orquestração, varre o repositório e popula as memórias.
---

Leia `{{AGENTS_ROOT}}/commands/orchestrator.md` para entender o protocolo da squad antes de prosseguir.

Aloque os modelos por tier:
- **Reasoning Tier** (modelos mais capazes): Product Owner, Architect, Tech Lead, **Security Specialist**.
- **Speed Tier** (modelos mais rápidos): Developer, QA Specialist, Ops.

### 1. Instalação e Configuração da Ferramenta
Este workflow é responsável por garantir que todos os agents, skills e commands da squad estejam corretamente instalados e configurados de acordo com a ferramenta de orquestração detectada (Gemini-CLI, Claude Code, Cursor, Antigravity, etc.).

**O frontmatter dos agents deve ser saneado para conter apenas o que a ferramenta suporta.**

Siga as diretrizes específicas da sua ferramenta:

#### ♊ Gemini-CLI
Utilize as documentações oficiais para garantir que todos os agents, skills e commands da squad em `.gemini/` estejam com a formatação e metadados corretos:
- [Skills](https://geminicli.com/docs/cli/skills/)
- [Subagents](https://geminicli.com/docs/core/subagents/)
- [Custom Commands](https://geminicli.com/docs/cli/custom-commands/)
**Ajuste de Agents**: Remova o atributo `trigger: always_on` do frontmatter dos agents e do orquestrador em `{{AGENTS_ROOT}}/`, pois ele é exclusivo do Antigravity.
**Orquestrador**: Garanta que o arquivo `GEMINI.md` na raiz do projeto aponte para o orquestrador da squad.

#### 🚀 Antigravity
Utilize as bases da Antigravity (D-O-E Framework) para garantir que as Directives e a Orchestration da squad em `.agents/` estejam alinhadas com os padrões de artefatos e execução da ferramenta. Consulte se necessário: https://antigravity.google/docs (ou documentação interna disponível).
**Ajuste de Agents**: Garanta que o atributo `trigger: always_on` esteja presente no frontmatter de todos os agents e do orquestrador.
**Orquestrador**: Garanta que o arquivo `AG.md` na raiz do projeto aponte para o orquestrador da squad.

#### ❄️ Claude Code
Utilize a documentação oficial da Anthropic para [Claude Code](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code) para validar se los **Subagents** em `.claude/agents/` e as **Skills** em `.claude/skills/` (seguindo o padrão `SKILL.md`) estão corretamente estruturados com o frontmatter e metadados exigidos.
**Ajuste de Agents**: Remova atributos não suportados como `trigger: always_on` dos agents e do orquestrador (`CLAUDE.md`).
**Orquestrador**: Garanta que o arquivo `CLAUDE.md` na raiz do projeto aponte para o orquestrador da squad.

#### 🖱️ Cursor AI
Utilize as diretrizes oficiais do Cursor para [Custom Rules](https://docs.cursor.com/context/rules-for-ai) e `.cursorrules` para garantir que as definições dos agentes e instruções da squad estejam otimizadas para o indexador do Cursor e para a integração com o Chat/Composer.
**Ajuste de Agents**: Como os arquivos são convertidos para `.mdc`, garanta que o frontmatter final siga o esquema XML/YAML do Cursor, removendo o `trigger` legado.

Se detectar incompatibilidades durante a instalação, ajuste ou sugira correções imediatas.

### 2. Discovery Estrutural e Memória (Varredura Robusta)
Após a configuração da ferramenta, este workflow deve garantir uma varredura completa do repositório para popular as memórias. Execute a skill `{{AGENTS_ROOT}}/skills/bootstrap/SKILL.md`: varra o repositório completo (manifestos, código-fonte, configurações, infra) e popule:
- `{{AGENTS_ROOT}}/memorys/business.md` — regras de negócio, terminologia de domínio, fluxos de permissão.
- `{{AGENTS_ROOT}}/memorys/architecture.md` — stack, NFRs, arquitetura macro, modelo de ameaças, controles de segurança ativos.
- `{{AGENTS_ROOT}}/memorys/guidelines.md` — padrões de código, lint, antipadrões, vulnerabilidades remediadas, **tom da squad**.

Ao finalizar, confirme ao usuário:
1. Stacks detectadas (linguagem, framework, banco, CI/CD).
2. Personalidade escolhida pela squad.
3. Setup concluído — pronto para receber a primeira demanda.
