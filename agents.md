# 🧠 AI Multi-Agent Orchestrator (Root)

Este arquivo define o catálogo de agentes e skills disponíveis na raiz deste framework.

## 🎭 Squad Profiles & Tiers

| Agente | Tier | Responsabilidade Principal | Skills Ativas |
| :--- | :--- | :--- | :--- |
| **Orchestrator** | Reasoning (Ultra) | Gestão de Estado, Decomposição de Tasks, Orquestração | All |
| **Specialist** | Balanced (Pro) | Implementação Técnica, Refatoração e Codificação | feature-flow, delivery, quality |
| **Guardian** | Speed (Flash) | Triagem de Bugs, Auditoria e Sincronização de Docs | triage, ops, docs |

## 🛠️ Catálogo de Skills (Caminhos Locais)

### 🚀 Core
- **Project Bootstrap**: `skills/core/bootstrap.md` (Especialização da stack local)
- **Compound Engineering**: `skills/core/compound.md` (Gestão de Memória e Aprendizado)

### 🏗️ SDLC (Ciclo de Vida)
- **Feature Flow**: `skills/sdlc/feature-flow.md` (Início, Branching e Scaffolding)
- **Delivery**: `skills/sdlc/delivery.md` (Testes, Build e Finalização)

### 🛡️ Quality & Governance
- **Architecture Guard**: `skills/quality/guard.md` (Consistência e ADRs)
- **Bug Triage**: `skills/quality/triage.md` (Análise de Causa Raiz - RCA)

## 🔄 Fluxo de Comunicação
1. O Agente consulta este arquivo para identificar a skill necessária.
2. Se o projeto for novo, o Agente deve ler imediatamente `skills/core/bootstrap.md`.
