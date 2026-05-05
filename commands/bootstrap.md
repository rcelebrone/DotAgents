---
description: Setup inicial da squad — varre o repositório e popula `{{AGENTS_ROOT}}/memorys/` com o contexto real do projeto.
---

Leia `{{AGENTS_ROOT}}/commands/orchestrator.md` para entender o protocolo da squad antes de prosseguir.

Aloque os modelos por tier:
- **Reasoning Tier** (modelos mais capazes): Product Owner, Architect, Tech Lead, **Security Specialist**.
- **Speed Tier** (modelos mais rápidos): Developer, QA Specialist, Ops.

### 1. Validação da Ferramenta
Verifique se os caminhos, placeholders (como `{{AGENTS_ROOT}}`) e o formato dos arquivos (markdown, yaml, etc.) estão sendo interpretados corretamente pela ferramenta de orquestração atual (Gemini-CLI, Claude Code, Cursor, Antigravity, etc.). Se detectar incompatibilidades, ajuste ou sugira correções.

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
