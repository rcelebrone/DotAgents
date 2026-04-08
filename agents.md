# 🧠 Central de Roteamento Multi-Agente (Registry)

Este projeto utiliza uma arquitetura de delegação em cascata. O modelo de inteligência que interage com o usuário DEVE ler os perfis abaixo na pasta `agents/` e instanciar (via sub-prompts ou chamadas de ferramenta) o agente correto para a tarefa.

## 👥 A Squad (Localizados em `agents/`)
- 👑 **Tech Lead** (`agents/techlead.md`): O Orquestrador. Ponto de entrada do usuário.
- 📐 **Architect** (`agents/architect.md`): Focado em integridade e estado de memória (`architecture.md`).
- 💻 **Dev Team** (`agents/dev-team.md`): A força motriz de escrita de código.
- 🐛 **QA Specialist** (`agents/qa-specialist.md`): Validação estrita e auditoria de logs.
- ⚙️ **Ops** (`agents/ops.md`): Fechamento de pacotes, dependências e deploy (`delivery.md`).

## 🔄 Topologia de Comunicação (Exemplo de Fluxo)
`User` ➔ `TechLead` (Planeja e divide) ➔ `DevTeam` (Codifica) ➔ `QASpecialist` (Testa) ➔ `Ops` (Versiona) ➔ `TechLead` (Informa o User).
