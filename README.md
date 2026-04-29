# Multi-Agent Orchestration Boilerplate

Este repositório é um template de referência para instalar uma squad completa e autônoma de Agentes de IA dentro de qualquer projeto de software.

## 🏗️ A Squad

O framework abandona o conceito de um único assistente genérico e instaura uma equipe especializada (`.agents/rules/`):

* 🎯 **Product Owner**: Interface com o usuário. Refina regras de negócio e define os Critérios de Aceite (DoD).
* 👑 **Tech Lead**: Orquestrador Técnico. Transforma os requisitos do PO em tarefas arquiteturais e gerencia o time.
* 📐 **Architect**: Cuida da integridade do sistema e mantém a memória viva (`.agents/memory/architecture.md`).
* 💻 **Developer**: Focado exclusivamente na escrita de código, testes unitários e refatoração.
* 🐛 **QA Specialist**: Focado em testes, auditoria de logs e isolamento de bugs (RCA).
* ⚙️ **Ops**: Responsável por CI/CD, dependências, build final e versionamento de entrega.

## 📁 Estrutura do Projeto

```
.agents/                        ← Este boilerplate é instalado aqui
├── rules/                      ← User Rules do Antigravity (Orquestração e Agentes)
│   ├── orchestrator.md         ← Orquestrador central + protocolo da squad (always_on)
│   ├── product-owner.md        ← Definição do PO (always_on)
│   ├── architect.md            ← Definição do Architect (always_on)
│   ├── techlead.md             ← Definição do Tech Lead (always_on)
│   ├── developer.md            ← Definição do Developer (always_on)
│   ├── qa-specialist.md        ← Definição do QA (always_on)
│   └── ops.md                  ← Definição do Ops (always_on)
├── memory/                     ← Memória viva do projeto (retroalimentada pela squad)
│   ├── business.md             ← Regras de negócio e domínio (governa: PO)
│   ├── architecture.md         ← Decisões arquiteturais e NFRs (governa: Architect)
│   └── guidelines.md           ← Padrões de código e tom da squad (governa: todos)
├── skills/                     ← Workflows reutilizáveis da squad
│   ├── core/bootstrap/         ← Setup inicial e descoberta de contexto
│   ├── core/compound/          ← Atualização de memória pós-merge
│   ├── sdlc/feature-flow/      ← Criação e orquestração de features
│   ├── sdlc/delivery/          ← Build, versionamento e deploy
│   ├── sdlc/refactor/          ← Refatoração segura
│   ├── quality/triage/         ← Isolamento de bugs e RCA
│   ├── quality/guard/          ← ADRs e conformidade arquitetural
│   ├── ops/infrastructure/     ← Auditoria de deps e infra
│   └── ops/squad-visualizer/   ← Dashboard visual da squad
├── docs/
│   ├── tasks/                  ← Tasks criadas durante o desenvolvimento
│   └── templates/              ← Templates de task e bug report
└── install/
    └── .cursorrules            ← Template para a raiz do projeto (Cursor)
```

## 🚀 Instalação

### Opção 1: Configuração Automática (Recomendado)

Se você estiver usando um agente compatível com Antigravity/User Rules (como este), basta digitar:

> "Read DotAgents/agent.md and configure"

O agente irá renomear a pasta para `.agents`, configurar as regras e iniciar o bootstrap automaticamente.

---

### Opção 2: Instalação Manual

#### 1. Injetar o boilerplate

Clone este repositório dentro do seu projeto destino renomeando a pasta para `.agents`:

```bash
git clone <url-deste-repo> .agents
```

#### 2. Configurar o Cursor (se aplicável)

Copie o arquivo de regras para a raiz do seu projeto:

```bash
cp .agents/install/.cursorrules .cursorrules
```

#### 3. Executar o Setup Inicial (Bootstrap)

**No Antigravity:** acione o workflow `bootstrap` (`.agents/workflows/bootstrap.md`).

**No Cursor ou outro agente:** envie o seguinte prompt:

> "Leia `.agents/rules/orchestrator.md` para entender o protocolo da squad. Atue como o **Tech Lead** (`.agents/rules/techlead.md`). Analise os modelos disponíveis neste ambiente e aloque os modelos com maior capacidade de raciocínio (Reasoning) para PO, Architect e você; e os mais rápidos (Speed) para Developer, QA e Ops. Em seguida, acione o **Product Owner** para executar `.agents/skills/core/bootstrap/SKILL.md`, varrendo este repositório e populando `.agents/memory/` com o contexto real do projeto."

---

## 🛠️ O Ciclo de Delegação Autônoma

**⚠️ Regra de Ponto Único (Delegação Padrão):** A Squad DEVE sempre ser acionada para orquestrar e executar as tarefas de ponta a ponta. O modelo ativo na janela de contexto de chat APENAS executará o trabalho caso o usuário requisite *explicitamente* para implementar algo por fora da Squad.

1. O **Product Owner** refina a ideia e cria a documentação de requisitos. (Se o usuário enviar a especificação já pronta, o PO apenas a avalia e imediatamente delega).
2. O **Tech Lead** lê os requisitos, aciona o **Architect** se necessário, e quebra a demanda técnica em `docs/todo/`.
3. O **Tech Lead** delega a execução sequencial ao **Developer**.
4. O **Developer** codifica e aciona o **QA Specialist** para rodar a auditoria e os testes.
5. Passando nos testes, a bola vai para o **Ops**, que gera o build de release e atualiza o versionamento.
6. O **Tech Lead** invoca `skills/core/compound/SKILL.md` para consolidar aprendizados em `memory/guidelines.md`.
7. O **Product Owner** faz a validação final da entrega contra os critérios de aceite.

## ⚡ Workflows Pré-configurados (Antigravity)

Após instalado em `.agents/`, os seguintes workflows estão prontos para uso imediato:

| Workflow | Trigger | Agente inicial |
|----------|---------|---------------|
| `bootstrap` | Setup inicial do projeto | Tech Lead → PO |
| `nova-feature` | Nova feature ou ideia | Product Owner |
| `corrigir-bug` | Bug ou incidente | Tech Lead |
| `revisao-arquitetural` | Design ou refatoração | Architect |
| `deploy` | Release ou dependências | Ops |

---

*Regra de Agnosticismo: Este framework, seus agentes, skills, orquestrador (`agents.md`) e este `README.md` são rigorosamente agnósticos. Nenhuma tecnologia específica de produto deve figurar nestas configurações.*

⚠️ **EXCEÇÃO ESTRATÉGICA (Memory State):** Os arquivos em `memory/` (`architecture.md`, `guidelines.md` e `business.md`) **NÃO SÃO AGNÓSTICOS**. Eles abrigam as decisões absolutas de arquitetura, negócio e stack do repositório onde a squad foi instalada. Em instalações limpas eles começam essencialmente em branco e DEVEM ser sistematicamente populados e atualizados pelos agentes conforme o projeto evolui.
