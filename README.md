# DotAgents — Multi-Agent Management Boilerplate

Template agnóstico para instalar uma squad multi-agente (PO, Architect, Tech Lead, Developer, QA, Security, Ops) em qualquer projeto que use ferramentas de gerenciamento de agentes.

A squad é regida por um manager central, tem personas com responsabilidades claras, skills reutilizáveis e uma memória viva específica do projeto.

## 🚀 Instalação

Primeiro, clone este repositório para dentro do seu projeto:

```
git clone [https://github.com/rodrigo-celebrone/DotAgents.git](https://github.com/rodrigo-celebrone/DotAgents.git) DotAgents
```

Agora, basta rodar o instalador unificado. Ele irá identificar e estruturar os arquivos de acordo com a ferramenta que você escolher e, ao final, excluirá a pasta de instalação automaticamente.

Você pode rodá-lo no modo interativo:
```bash
chmod +x DotAgents/install.sh
./DotAgents/install.sh
```

Ou, para automações (CI/CD ou executado por IAs), passe o argumento da sua ferramenta:
```bash
./DotAgents/install.sh --antigravity  # opções: --antigravity, --claude ou --cursor
```

---

## Após a instalação: O Bootstrap

Independente da ferramenta (Terminal ou IDE), a primeira ação sempre deve ser iniciar o reconhecimento do projeto pela Squad.

> 🤖 Prompt para a sua IA (Copie e cole): "Siga rigorosamente as instruções do workflow de inicialização localizado em commands/dot-agent-bootstrap.md para calibrar a squad neste repositório."

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

## 📁 Estrutura da Squad Pós-Instalação

Após rodar o instalador e ele se autodestruir, os artefatos estarão injetados de forma invisível no diretório padrão da sua ferramenta (ex: .agents/, .claude/, etc) com a seguinte estrutura lógica:

- agents/: Definições das personas.
- skills/: Habilidades especializadas executáveis.
- commands/: Workflows e roteamento de tarefas (Manager).
- memorys/: (Visível na raiz do seu projeto) Memória viva contínua (Business, Architecture, Guidelines).

---

## 📄 Licença

Consulte o arquivo [`license.md`](license.md) para detalhes sobre os termos de uso.
