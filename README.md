# DotAgents — Multi-Agent Orchestration Boilerplate

Template agnóstico para instalar uma squad multi-agente (PO, Architect, Tech Lead, Developer, QA, Security, Ops) em qualquer projeto que use ferramentas de orquestração de agentes.

A squad é regida por um **orquestrador central**, tem **personas** com responsabilidades claras, **skills** reutilizáveis e uma **memória viva** específica do projeto.

---

## 🚀 Instalação

Primeiro, clone este repositório como `DotAgents/` dentro do seu projeto:

```bash
git clone https://github.com/rodrigo-celebrone/DotAgents.git DotAgents
```

Agora, siga as instruções de acordo com a ferramenta que você utiliza:

### ♊ Gemini-CLI
#### 1. Execute o instalador
```bash
./DotAgents/instalador-gemini-cli.sh
```
#### 2. 🤖 Prompt para o LLM
> "Você agora está equipado com a squad **DotAgents**. Localize os arquivos de configuração em `.gemini/` e execute o workflow de inicialização descrito em `commands/bootstrap.md`. Assuma as personas de **Tech Lead**, **Architect** e **Product Owner** para analisar o projeto e preencher os arquivos em `memorys/` com a stack técnica, regras de negócio e guidelines detectados."

---

### 🚀 Antigravity
#### 1. Execute o instalador
```bash
./DotAgents/instalador-antigravity.sh
```
#### 2. 🤖 Prompt para o LLM
> "Você agora está equipado com a squad **DotAgents**. Localize os arquivos de configuração em `.gemini/` e execute o workflow de inicialização descrito em `commands/bootstrap.md`. Assuma as personas de **Tech Lead**, **Architect** e **Product Owner** para analisar o projeto e preencher os arquivos em `memorys/` com a stack técnica, regras de negócio e guidelines detectados."

---

### ❄️ Claude Code
#### 1. Execute o instalador
```bash
./DotAgents/instalador-claude.sh
```
#### 2. 🤖 Prompt para o LLM
> "Você agora está equipado com a squad **DotAgents**. Localize os arquivos de configuração em `.claude/` e execute o workflow de inicialização descrito em `commands/bootstrap.md`. Assuma as personas de **Tech Lead**, **Architect** e **Product Owner** para analisar o projeto e preencher os arquivos em `memorys/` com a stack técnica, regras de negócio e guidelines detectados."

---

### 🖱️ Cursor AI
#### 1. Execute o instalador
```bash
./DotAgents/instalador-cursor.sh
```
#### 2. 🤖 Prompt para o LLM
> "Você agora está equipado com a squad **DotAgents**. Localize os arquivos de configuração em `.cursor/` e execute o workflow de inicialização descrito em `commands/bootstrap.md`. Assuma as personas de **Tech Lead**, **Architect** e **Product Owner** para analisar o projeto e preencher os arquivos em `memorys/` com a stack técnica, regras de negócio e guidelines detectados."

---

## 🏗️ A Squad

| Persona | Responsabilidade |
|---|---|
| 🎯 **Product Owner** | Refina regras de negócio, define DoD. |
| 🏛️ **Architect** | Integridade sistêmica, ADRs. |
| 👑 **Tech Lead** | Triagem técnica, criação de tasks, coordenação ágil. |
| 💻 **Developer** | Implementação Clean Code + TDD. |
| 🧪 **QA Specialist** | Validação funcional, RCA de bugs. |
| 🔒 **Security Specialist** | Threat modeling, AppSec audit. |
| 🚀 **Ops** | Ciclo de entrega local, deploy. |

---

## 📁 Estrutura

- `agents/`: Definições das personas.
- `skills/`: Habilidades especializadas.
- `commands/`: Workflows e orquestração.
- `memorys/`: Memória viva (Business, Architecture, Guidelines).

---

## 📄 Licença

Consulte o arquivo [`license.md`](license.md) para detalhes sobre os termos de uso.
