# 🧠 AI Agents Orchestrator (Main)

Este arquivo define o catálogo de skills disponíveis para os agentes de IA neste repositório. Cada skill é auto-contida e evolui de acordo com as restrições que for aprendendo do projeto específico.

> **Instrução Crítica para o Agente**: Sempre consulte este arquivo antes de iniciar qualquer tarefa para identificar qual skill deve ser carregada no escopo. Se este projeto acabou de ser criado e o usuário pedir para instalar os agentes, **leia imediatamente o `skills/project-bootstrap/SKILL.md`**.

---

## 🚀 Bootstrap & Setup

- **Project Bootstrap**: Analisa o código do repositório destino e formata / altera todas as regras listadas abaixo e seus arquivos correspondentes para a linguagem e framework utilizados localmente. (Roda no setup inicial)
- **Compound Engineering**: Coleta e injeta arquitetura e knowledge entre sessões (modificando `guidelines.md` e `architecture.md`).

## 🛠️ Skills de Ciclo de Vida (SDLC)

- **Feature Initialization (`start-feature`)**: Cuida do setup de novas features, criação de branches e decomposição de tasks em `.agents/docs/tasks/`.
- **Feature Completion (`finish-feature`)**: Executa testes locais, gera builds, atualiza changelog e versionamento, e faz o push final.

## 🏛️ Skills de Governança e Arquitetura

- **ADR Automator (`adr-automator`)**: Formaliza decisões técnicas através de *Architectural Decision Records*.
- **Architecture Consistency Checker (`architecture-checker`)**: Garante que o código respeite os padrões definidos nas diretrizes arquiteturais locais.
- **Onboarding & Scaffolding (`scaffolding`)**: Padroniza a criação de novas entidades e boilerplate de código adaptados ao framework alvo.

## 🛡️ Skills de Manutenção e Qualidade

- **Documentation Updater (`documentation-updater`)**: Mantém o README e docs técnicos sincronizados sempre que variáveis, fluxos ou diagramas mudam.
- **Dependency Guard (`dependency-guard`)**: Monitora vulnerabilidades ou avisa as melhores práticas de update de bibliotecas.
- **Bug Triage & RCA (`bug-triage`)**: Analisa logs de erro, localiza provável stacktrace defeituoso e automatiza a criação de tasks de correção.
