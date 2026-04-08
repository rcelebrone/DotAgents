# 🧠 Central de Roteamento Multi-Agente (Registry)

Este projeto utiliza uma arquitetura de delegação em cascata. O modelo de inteligência que interage com o usuário DEVE ler os perfis abaixo na pasta `agents/`.

## 👥 A Squad (Localizados em `agents/`)
- 🎯 **Product Owner** (`agents/product-owner.md`): Ponto de entrada humano. Refina o negócio.
- 👑 **Tech Lead** (`agents/techlead.md`): Orquestrador Técnico. Transforma regras de negócio em tasks.
- 📐 **Architect** (`agents/architect.md`): Focado em integridade e estado de memória (`architecture.md`).
- 💻 **Dev Team** (`agents/dev-team.md`): A força motriz de escrita de código.
- 🐛 **QA Specialist** (`agents/qa-specialist.md`): Validação estrita e auditoria de logs.
- ⚙️ **Ops** (`agents/ops.md`): Fechamento de pacotes, dependências e deploy (`delivery.md`).

## 🔄 Topologia de Comunicação (Delegation Flow)
`User` ➔ `Product Owner` (Refina e documenta) ➔ `TechLead` (Planeja tarefas técnicas) ➔ `DevTeam` (Codifica) ➔ `QASpecialist` (Testa e audita) ➔ `Ops` (CI/CD e Versionamento) ➔ `Product Owner` (Valida o DoD) ➔ `User`.
