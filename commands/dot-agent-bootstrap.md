---
name: bootstrap
description: Executa a calibração inicial da squad no repositório. Varre o código estrutural e popula as memórias raiz.
---

# Workflow: Bootstrap

**DIRETRIZ DE EXECUÇÃO:** Não infira configurações. Execute rigorosamente a sequência de passos abaixo.

## 1. Verificação de Integridade e Configuração Explícita do Ecossistema
Verifique o sistema de arquivos para identificar o ambiente de execução atual. A instalação só é válida se UMA das três condições abaixo for verdadeira. **NÃO tente adivinhar** a configuração do ambiente, aplique RIGOROSAMENTE as regras documentadas para a ferramenta detectada:

- **Antigravity (IDE/CLI):**
  - Informe de forma explícita que o arquivo `AGENTS.md` **DEVE** existir na raiz do projeto. Se não existir, ele deve ser criado.
  - O arquivo `AGENTS.md` deve seguir as instruções de configuração de ambiente descritas em:
    - https://antigravity.google/docs/cli-subagents
    - https://antigravity.google/docs/cli-permissions
    - https://antigravity.google/docs/cli-sandbox
  - **Regra Explícita de Orquestração:** Isso é para garantir que o arquivo `commands/manager.md` e os agentes em `agents/` sejam usados e responsáveis por orquestrar cada solicitação interceptada pelo `AGENTS.md`. (Fluxo: o `AGENTS.md` recebe o user input > chama o `manager.md` para definir como seguir e qual agente usar > o agente escolhido executa o processo de acordo com as regras dele).

- **Claude Code:**
  - Confirme a existência do arquivo `CLAUDE.md` na raiz e do diretório `.claude/`.
  - **Regra Explícita:** O Claude Code não possui subdiretórios ativos de subagentes isolados, ele baseia seu contexto no arquivo principal. Você DEVE atualizar o arquivo `CLAUDE.md` para incluir referências e âncoras explícitas aos arquivos em `.claude/agents/*.md` e `.claude/commands/*.md`. Garanta que, ao instruir um prompt para uma persona (ex: "@TechLead"), o Claude saiba de onde extrair a identidade do Tech Lead.

- **Cursor AI:**
  - Confirme a existência do arquivo `CURSOR.md` na raiz e do diretório `.cursor/rules/`.
  - **Regra Explícita:** O Cursor gerencia a inteligência através do framework de Cursor Rules (`.mdc`). Confirme que todos os agentes e commands estão formatados como `.mdc` em `.cursor/rules/`. Se alguma persona não possuir o frontmatter correto (`description`, `globs`, e `alwaysApply`), adicione. A regra principal de coordenação (manager) DEVE estar com `alwaysApply: true`.

Se nenhuma condição for atendida, aborte o processo imediatamente e informe: *"Falha de integridade: Ecossistema de agentes não detectado na raiz do projeto. Reinstale via install.sh."*

## 2. Varredura Estrutural (Discovery)
Execute a leitura profunda do projeto utilizando a ferramenta/skill correspondente definida em `{{AGENTS_ROOT}}/skills/bootstrap/SKILL.md`.
Analise manifestos de dependências (ex: `package.json`, `pyproject.toml`, `go.mod`), arquivos de configuração de CI/CD e a estrutura de pastas do código-fonte.

## 3. População de Memória (Escrita)
Com base nos dados coletados no Passo 2, você DEVE escrever e popular os arquivos localizados no diretório raiz `memorys/`:

- **`memorys/business.md`**: Escreva o propósito do projeto, as regras de negócio identificadas e o glossário do domínio.
- **`memorys/architecture.md`**: Documente a stack tecnológica exata (Linguagem, Framework, Banco de Dados, CI/CD), a arquitetura macro e o modelo de infraestrutura detectado.
- **`memorys/guidelines.md`**: Registre padrões de linting, convenções de código detectadas e defina explicitamente o **Tom de Voz da Squad** (Ex: Neutro, Técnico-Rígido, Cordial). Se o usuário não especificou, adote "Técnico-Rígido".

## 4. Confirmação Final
Não gere textos longos de introdução. Ao terminar as escritas, apresente OBRIGATORIAMENTE o seguinte sumário final:

**[BOOTSTRAP CONCLUÍDO]**
- **Stack:** [Lista de tecnologias principais encontradas]
- **Tom da Squad:** [Tom configurado em guidelines.md]
- **Status:** Pronta para receber tarefas.
