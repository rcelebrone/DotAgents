Skill: Feature Initialization & Task Orchestrator
1. Descrição Geral
Esta skill é responsável por orquestrar o início de qualquer novo trabalho de desenvolvimento. Ela garante que o agente nunca trabalhe na branch principal, siga padrões de nomenclatura rigorosos e decomponha requisitos de alto nível em unidades de trabalho (tasks) documentadas.
2. Gatilhos de Ativação (Triggers)
A skill deve ser disparada automaticamente quando o utilizador solicitar:
 * "Implementa a funcionalidade [X]"
 * "Crie um novo módulo para [Y]"
 * "Resolve o bug [Z]"
 * "Refactoriza o componente [W]"
3. Protocolo de Branching
O agente deve classificar a intenção do utilizador e criar uma branch utilizando o seguinte padrão: <tipo>/<nome-da-feature-kebab-case>.
Convenções de Tipo:
 * feat: Para novas funcionalidades.
 * fix: Para correções de bugs.
 * refactor: Para melhorias de código.
 * chore: Para tarefas de manutenção.
4. Orquestração de Tarefas (.agents/docs/tasks/)
Sempre que a skill for ativada, o agente deve:
 * Criar a branch correspondente.
 * Criar na pasta .agents/docs/tasks/ um arquivo Markdown para cada task identificada no escopo da funcionalidade, seguindo a nomenclatura 001-nome-da-task.md.
