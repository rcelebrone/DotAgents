---
name: dot-agent-bootstrap
description: Executa a calibração inicial da squad no repositório — varre o código e popula as memórias raiz. Exceção de protocolo (setup-time, fora do SDLC).
---

# Workflow: Bootstrap da Squad

> **Exceção de protocolo (setup-time):** este workflow roda FORA do SDLC da squad — ele prepara o ambiente e **só escreve em `memories/*`**. Qualquer outra mudança identificada durante o bootstrap vira demanda normal via Manager. **NÃO edite `CLAUDE.md`/`AGENTS.md`** — o bloco de roteamento raiz é gerido pelo instalador (`install.sh`), entre os marcadores `<!-- dotagents:begin -->` e `<!-- dotagents:end -->`.

**DIRETRIZ DE EXECUÇÃO:** não infira configurações. Execute rigorosamente a sequência abaixo.

## 1. Verificação de Integridade
A instalação é válida se UMA das condições abaixo for verdadeira:

- **Antigravity (IDE/CLI):** `AGENTS.md` na raiz contém o bloco gerido do DotAgents e `.agents/{agents,skills,commands}/` existe. Subagentes nativos em `.agents/agents/*.md` (docs: https://antigravity.google/docs/cli/subagents , https://antigravity.google/docs/cli/permissions , https://antigravity.google/docs/cli/sandbox ; hooks: https://antigravity.google/docs/hooks — atenção: a página de hooks NÃO fica sob `/docs/cli/`). **Verifique com `/hooks` (no TUI) ou `agy inspect` que o hook `dotagents` está carregado** (eventos PreToolUse e PreInvocation).
- **Claude Code:** `CLAUDE.md` na raiz contém o bloco gerido (com o import `@.claude/commands/manager.md`) e `.claude/{agents,skills,commands}/` existe. **O Claude Code POSSUI subagentes nativos** (`.claude/agents/*.md`) — confirme que as 7 personas estão presentes; os gates QA/Review/Security são despachados como subagentes (manager § ⚙️). **Confirme via `/hooks` que `dotagents-gate` e `dotagents-remind` estão registrados** (PreToolUse e UserPromptSubmit).
- **Cursor AI:** `AGENTS.md` na raiz contém o bloco gerido, `.cursor/rules/dotagents-manager.mdc` existe com `alwaysApply: true`, e `.cursor/{agents,skills,commands}/` existe. **Confirme em `.cursor/hooks.json`** as entradas `preToolUse` (gate) e `sessionStart` (remind).

Nenhuma condição atendida → aborte: *"Falha de integridade: ecossistema da squad não detectado. Reinstale via install.sh (a pasta DotAgents/ é preservada por padrão para permitir reinstalação)."*

## 2. Varredura Estrutural (Discovery)
Execute `{{AGENTS_ROOT}}/skills/squad-bootstrap/SKILL.md`: manifestos de dependências (`package.json`, `pyproject.toml`, `go.mod`, ...), configuração de CI/CD e estrutura de pastas do código-fonte.

## 3. População de Memória (única escrita permitida)
- **`memories/business.md`**: propósito do projeto, regras de negócio identificadas, glossário de domínio.
- **`memories/architecture.md`**: stack exata (linguagem, framework, banco, CI/CD), arquitetura macro, infraestrutura; comandos de build/test/audit da stack; se houver pipeline de publicação, registre o procedimento em § Deploy.
- **`memories/guidelines.md`**: padrões de lint, convenções detectadas e o **Tom de Voz da Squad** — pergunte ao usuário; sem resposta, mantenha o default **Neutro**.
- **Memória nativa da ferramenta (se existir):** se a sua build tiver mecanismo nativo de memória/instruções persistentes, registre nele UMA única diretiva: *"Toda demanda neste repositório segue `{{AGENTS_ROOT}}/commands/manager.md` (DotAgents)"*. Não duplique o conteúdo das memórias da squad nesse mecanismo.
Use entradas datadas `[AAAA-MM-DD][bootstrap]`.

## 4. Confirmação Final
Sem textos longos de introdução. Ao terminar, apresente OBRIGATORIAMENTE:

**[BOOTSTRAP CONCLUÍDO]**
- **Stack:** [tecnologias principais encontradas]
- **Tom da Squad:** [tom configurado em guidelines.md]
- **Modo de Execução:** [subagentes | persona-shift — conforme manager § ⚙️]
- **Status:** pronta para receber demandas (o Manager classifica e roteia automaticamente).
