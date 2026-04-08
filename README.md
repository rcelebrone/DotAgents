# AI Agents Framework (Root)

Este repositório é um template de referência contendo **Skills** e **Orquestradores** genéricos para agentes de IA atuarem como engenheiros autônomos ou assistentes de desenvolvimento em qualquer projeto de software.

## 🏗️ Estrutura do Framework

O framework opera diretamente na raiz do diretório, eliminando a necessidade de pastas ocultas e simplificando o contexto da IA para máxima eficiência de tokens:

* **`agents.md`**: O cérebro da squad. Define perfis de agentes (**Orchestrator**, **Specialist**, **Guardian**) e mapeia as habilidades disponíveis.
* **`architecture.md`**: Memória técnica. Mantém o estado da stack identificado, decisões de design e fluxos de dados.
* **`guidelines.md`**: Memória de restrições. Armazena padrões de código, antipadrões locais e aprendizados acumulados entre sessões.
* **`skills/`**: Habilidades granulares divididas por domínios funcionais:
    * **Core**: Especialização de stack (`bootstrap.md`) e gestão de memória (`compound.md`).
    * **SDLC**: Início de funcionalidades (`feature-flow.md`) e finalização de tarefas (`delivery.md`).
    * **Quality**: Governança arquitetural (`guard.md`) e triagem de bugs (`triage.md`).

## 🚀 Como Instalar e Configurar

Para transformar qualquer repositório em um ambiente de desenvolvimento assistido por IA:

1.  **Instalação**: Copie todo o conteúdo deste framework (pastas `skills/` e arquivos `.md` da raiz) para a raiz do seu projeto destino (ou em uma pasta dedicada como `.agents/`).
2.  **Inicialização**: Na sua IDE, envie o seguinte prompt inicial para o agente de IA:
    > "Por favor, execute o **project-bootstrap** (`skills/core/bootstrap.md`) para ajustar as skills para este projeto."
3.  **Adaptação**: O agente analisará automaticamente sua base de código (linguagens, frameworks e arquitetura) e especializará as habilidades para sua stack específica.

## 🛠️ Ciclo de Trabalho Autônomo

O framework segue um fluxo rigoroso para garantir a integridade do sistema:

* **Planejamento**: O agente decompõe requisitos em tarefas documentadas na pasta `docs/tasks/`.
* **Desenvolvimento**: Utiliza a skill `feature-flow.md` para gerenciar o isolamento de branches e criar código padronizado.
* **Governança**: Valida a arquitetura e registra decisões técnicas (*Architectural Decision Records*) via `guard.md`.
* **Aprendizado**: Após cada entrega, a skill `compound.md` injeta novos conhecimentos técnicos nos arquivos de memória (`architecture.md` e `guidelines.md`).

---
*Este framework é agnóstico a linguagens e focado em orquestração multi-agente de alto desempenho.*
