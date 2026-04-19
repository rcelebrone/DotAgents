Implementation Plan — Preparação do Boilerplate

Versão: 1.0 | Fase: Architecture / Readiness

🏗 Contexto Técnico

Framework: Dot-Agents (Agnóstico).

Mecanismo de Setup: Skill core/bootstrap.

Roteamento: Tiering de modelos baseado em complexidade de Role.

🛠 Estratégia de Preparação

1. Refinamento das Roles (Agents)

Ajustar agents/ para que o campo model aceite variáveis ou categorias (ex: tier: reasoning ou tier: speed).

Instruir os agentes no agent.md a avaliarem a complexidade da tarefa antes de sugerir o uso de um modelo específico, visando economia de tokens.

2. Inteligência de Descoberta (Skill Bootstrap)

A skill não deve ter comandos fixos. Ela deve conter um "Decision Tree":

Se detectar package.json -> Configura delivery para npm/yarn/pnpm.

Se detectar requirements.txt ou pyproject.toml -> Configura delivery para pip/poetry/pytest.

E assim por diante.

3. Workflow de Personalidade

Definir em rules/guidelines.md (o template) que a primeira ação do PO após o bootstrap é lançar o prompt de humor: "Setup completo. Opero em modo Neutro por padrão. Deseja injetar um humor específico (Sarcástico, Motivacional, etc.) ou manter a neutralidade?"

4. Gestão de Memória (Rules)

Garantir que rules/architecture.md, business.md e guidelines.md sejam distribuídos como "Vasilhas Vazias" com instruções de preenchimento automatizado.

📂 Estrutura de Arquivos

Nenhuma mudança estrutural, apenas refinamento de conteúdo nos .md para garantir o agnosticismo.
