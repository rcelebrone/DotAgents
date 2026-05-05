---
description: Setup inicial da squad — varre o repositório e popula `{{AGENTS_ROOT}}/memorys/` com o contexto real do projeto.
---

Leia `{{AGENTS_ROOT}}/commands/orchestrator.md` para entender o protocolo da squad antes de prosseguir.

Aloque os modelos por tier:
- **Reasoning Tier** (modelos mais capazes): Product Owner, Architect, Tech Lead, **Security Specialist**.
- **Speed Tier** (modelos mais rápidos): Developer, QA Specialist, Ops.

### 1. Validação da Ferramenta
Verifique se os caminhos, placeholders (como `{{AGENTS_ROOT}}`) e o formato dos arquivos (markdown, yaml, etc.) estão sendo interpretados corretamente pela ferramenta de orquestração atual (Gemini-CLI, Claude Code, Cursor, Antigravity, etc.).

Siga as diretrizes específicas da sua ferramenta:

#### ♊ Gemini-CLI
Utilize as documentações oficiais para garantir que todos os agents, skills e commands da squad em `.gemini/` estejam com a formatação e metadados corretos:
- [Skills](https://geminicli.com/docs/cli/skills/)
- [Subagents](https://geminicli.com/docs/core/subagents/)
- [Custom Commands](https://geminicli.com/docs/cli/custom-commands/)

#### 🚀 Antigravity
Utilize as bases da Antigravity (D-O-E Framework) para garantir que as Directives e a Orchestration da squad em `.gemini/antigravity/` estejam alinhadas com os padrões de artefatos e execução da ferramenta. Consulte se necessário: https://antigravity.google/docs (ou documentação interna disponível).

#### ❄️ Claude Code
Utilize a documentação oficial da Anthropic para [Claude Code](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code) para validar se os **Subagents** em `.claude/agents/` e as **Skills** em `.claude/skills/` (seguindo o padrão `SKILL.md`) estão corretamente estruturados com o frontmatter e metadados exigidos.

#### 🖱️ Cursor AI
Utilize as diretrizes oficiais do Cursor para [Custom Rules](https://docs.cursor.com/context/rules-for-ai) e `.cursorrules` para garantir que as definições dos agentes e instruções da squad estejam otimizadas para o indexador do Cursor e para a integração com o Chat/Composer.

Se detectar incompatibilidades, ajuste ou sugira correções.

### 2. Discovery Estrutural e Memória
Execute a skill `{{AGENTS_ROOT}}/skills/core/bootstrap/SKILL.md`: varra o repositório completo (manifestos, código-fonte, configurações, infra) e popule:
- `{{AGENTS_ROOT}}/memorys/business.md` — regras de negócio, terminologia de domínio, fluxos de permissão.
- `{{AGENTS_ROOT}}/memorys/architecture.md` — stack, NFRs, arquitetura macro, modelo de ameaças, controles de segurança ativos.
- `{{AGENTS_ROOT}}/memorys/guidelines.md` — padrões de código, lint, antipadrões, vulnerabilidades remediadas, **tom da squad**.

> Nota: a configuração da ferramenta de orquestração (Claude Code, Cursor, Antigravity, Gemini-CLI, etc.) é responsabilidade do instalador raiz `agent.md`, não deste workflow. Se este workflow foi acionado isoladamente em um projeto onde os symlinks ainda não existem, oriente o usuário a digitar `configure DotAgents` primeiro.

Ao finalizar, confirme ao usuário:
1. Stacks detectadas (linguagem, framework, banco, CI/CD).
2. Personalidade escolhida pela squad.
3. Setup concluído — pronto para receber a primeira demanda.
