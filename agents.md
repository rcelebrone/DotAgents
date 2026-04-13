# 🧠 Central de Orquestração de Agentes (Registry)

Este arquivo é o orquestrador principal da squad multidisciplinar. Ao receber uma entrada do usuário, o modelo ativo **DEVE** analisar a intenção e delegar a execução inicial para a Squad. A equipe atuará de forma autônoma, delegando o trabalho Agente-para-Agente seguindo as práticas Agile e Lean. IMPORTANTE: Somente desvie da Squad caso o usuário explicitamente solicite a execução por fora, pela janela de contexto atual. Caso contrário, toda a implementação e concepção da demanda perpassa pelos papéis abaixo.

## 🗺️ Mapa da Squad (Localizados em `.agents/agents/`)

- 🎯 **[Product Owner](.agents/agents/product-owner/agent.md)**: Ponto de entrada para novas features (Feature Requests) e refinamento de regras de negócio.
- 👑 **[Tech Lead](.agents/agents/techlead/agent.md)**: Triagem de bugs, orquestração técnica e coordenação ágil das tarefas.
- 📐 **[Architect](.agents/agents/architect/agent.md)**: Integridade sistêmica, segurança e manutenção de padrões.
- 💻 **[Dev Team](.agents/agents/dev-team/agent.md)**: Construção contínua (Clean Code, TDD).
- 🐛 **[QA Specialist](.agents/agents/qa-specialist/agent.md)**: Validação estruturada, auditoria de código e prevenção de anomalias.
- ⚙️ **[Ops](.agents/agents/ops/agent.md)**: Entrega final, CI/CD, gerenciamento de dependências e infraestrutura.

## 🔄 Fluxos de Orquestração Autônoma (Lean Flow)

O orquestrador analisa a entrada e identifica o fluxo adequado para delegar ao primeiro agente, que seguirá o fluxo puxando (Pull System) e delegando o trabalho conforme necessário:

### 1. Novo Recurso ou Ideia (Feature Request)
`Usuário ➔ Product Owner`
1. O **Product Owner** refina a necessidade de negócio, definindo Critérios de Aceite (DoD). Ele pode utilizar `.agents/skills/sdlc/feature-flow/SKILL.md`. (Se a task enviada pelo usuário humano já possuir requisitos redigidos no formato adequado, o PO analisa e se valida repassa de imediato sem recriar etapas).
2. O PO delega para o **Tech Lead** especificando o "O Que".
3. O **Tech Lead** traduz essas necessidades em especificações técnicas (criando tarefas isoladas em `.agents/docs/tasks/` baseadas no template `.agents/docs/templates/task.md`) e aciona o **Dev Team**.
4. O **Dev Team** desenvolve e passa os incrementos para testes pelo **QA Specialist**.
5. O QA valida e encaminha para **Ops** integrar.

### 2. Relato de Bug ou Anomalia (Incident Management)
`Usuário ➔ Tech Lead`
1. O **Tech Lead** atua na frente de incidentes executando `.agents/skills/quality/triage/SKILL.md` para isolar e entender o problema.
2. Com o diagnóstico em mãos, ele repassa o escopo de correção para o **Product Owner** validar se é necessária uma adaptação de negócio ou refina os critérios.
3. Se for correção técnica, o Tech Lead utiliza `.agents/skills/sdlc/feature-flow/SKILL.md` para criar a demanda de correção em `.agents/docs/tasks/` baseada no template `.agents/docs/templates/bug.md` e delega ao **Dev Team**.
4. Fluxo contínuo: **Dev Team** codifica ➔ **QA Specialist** valida ➔ **Ops** deploya.

### 3. Dúvida Técnica, Design Arquitetural ou Refatoração
`Usuário ➔ Architect`
1. O **Architect** avalia impactos de segurança, manutenibilidade e escalabilidade.
2. Atualiza as decisões arquiteturais da aplicação e as diretrizes não funcionais no `.agents/rules/guidelines.md`.
3. Delega o plano de refatoração para o **Tech Lead**.

### 4. Deploy, Dependências e CI/CD
`Usuário ➔ Ops`
1. O **Ops** analisa logs de Pipeline, atualizações do dependabot e automação de builds utilizando `.agents/skills/ops/infrastructure/SKILL.md` e `.agents/skills/sdlc/delivery/SKILL.md`.

## 🧭 Desacoplamento e Independência Prática (Agnosticismo)
Para manter este modelo de agentes plug-and-play e a squad efetiva para qualquer projeto estrutural:
- **Ausência de Contexto Acoplado:** As configurações (`agent.md`) e habilidades (`SKILL.md`) **NÃO** possuem regras especificas de um produto.
- **Regras de Domínio:** Ficam centralizadas de maneira global em `.agents/rules/business.md`, e seus desdobramentos atômicos ficam persistidos nos arquivos de tarefas da pasta `.agents/docs/tasks/` (via Spec Kit).
- **Diretrizes e Padrões (NFRs):** Registrados em `.agents/rules/guidelines.md` (e possíveis documentações correlatas em docs). Todos os agentes leem o `rules/guidelines.md` para adequação antes de codificar. **Nota fundamental**: Diferente de todo o framework (que independe de contextos), as decisões mantidas em `.agents/rules/business.md`, `.agents/rules/architecture.md` e `.agents/rules/guidelines.md` NÃO SÃO agnósticas. Eles representam a memória técnica e de negócios estrita do seu repositório. Esses arquivos começam em branco para os novos projetos e a squad tem a responsabilidade de alimentá-los agressivamente com as diretrizes e escolhas conforme avançam.
