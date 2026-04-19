Feature Spec 000 — Universal Bootstrap Readiness

Status: 📝 Draft | Prioridade: P0 | Dono: SpecKit Architect

📝 Descrição (O Que e Por quê)

Preparar o framework Dot-Agents para ser um boilerplate "Plug-and-Play". O framework deve estar preparado para, ao ser ativado em um novo ambiente, identificar a stack tecnológica, otimizar o custo de tokens e configurar a personalidade da squad via interação com o usuário.

🎯 User Stories (US)

US001 [P1]: Como Bootstrap, devo possuir uma skill de descoberta (discovery) preparada para ler manifestos (package.json, go.mod, etc.) sem assumir uma linguagem prévia.

US002 [P1]: Como Framework, devo oferecer um fluxo de configuração de humor que inicia como "Neutro", mas possui um gatilho de interação para o usuário personalizar no setup.

US003 [P1]: Como Arquiteto, devo pré-configurar os agentes no agents.md com lógica de fallback para modelos "Small/Fast" para tarefas de execução e "Reasoning" para planejamento.

US004 [P2]: Como DevOps, a skill de delivery deve ser um template dinâmico que se autoprograma conforme a stack detectada no momento da instalação.

✅ Critérios de Aceite (DoD)

[ ] Arquivo skills/core/bootstrap/SKILL.md contém a lógica de "Perguntar Humor".

[ ] Manifestos de agentes em agents/ possuem metadados de tiering de modelo (Speed vs Reasoning).

[ ] O agents.md (Registry) possui instruções claras sobre o ciclo de vida: Identificar Stack -> Perguntar Humor -> Roteamento de Modelos.

[ ] Arquivos em rules/ estão limpos, apenas com boilerplates de instrução, prontos para receber dados do novo projeto.

🧪 Independent Test

Clonar este bootstrap em um projeto Python (ex: com requirements.txt).

Clonar este bootstrap em um projeto Node (ex: com package.json).

Em ambos, a skill de bootstrap deve ser capaz de identificar a diferença e sugerir os modelos corretos e o humor.
