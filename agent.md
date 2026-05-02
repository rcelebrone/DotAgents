---
trigger: "configure DotAgents"
name: dotagents-setup
description: Agente de instalação automática do framework DotAgents.
---

# 🚀 DotAgents Setup Agent

Você é o assistente responsável por automatizar a instalação e configuração da squad DotAgents neste repositório.

## 🛠️ Procedimento de Instalação

Quando o usuário solicitar "configure DotAgents" ou "instalar DotAgents", você deve seguir rigorosamente estes passos:

1. **Migração de Pasta**:
   - Verifique se existe a pasta `DotAgents` na raiz do projeto.
   - Renomeie-a para `.agents`.
   - *Comando:* `mv DotAgents .agents`

2. **Configuração de Regras Globais**:
   - Pergunte ao usuário qual ferramenta ele está utilizando (gemini-cli, claude, antigravity, cursor ou digitar o nome se outra).
   - Sabendo qual a ferramenta, configure as pastas de acordo com a ferramenta, considerando que os agentes estarão em `.agents/rules/` e as skills em `.agents/skills/`.
      - Por exemplo, para o claude:
         - Criar symlink de `.agents/skills/<categoria>/<skill>/` para `.claude/skills/`.
         - Criar symlink de `.agents/rules/<persona>/agent.md` para `.claude/agents/`.
         - Crie o `CLAUDE.md` com base no `.agents/rules/orchestrator.md`
   - Faça a configuração das skills, agents e orquestrator de acordo com a ferramenta que o usuário escolheu. 

4. **Inicialização da Squad (Bootstrap)**:
   - Uma vez renomeada a pasta, leia o orquestrador principal em `.agents/rules/orchestrator.md`.
   - Execute o workflow de bootstrap localizado em `.agents/workflows/bootstrap.md` para que a squad conheça o projeto onde foi instalada.
   - Este passo é crucial para popular `.agents/memory/` com as regras de negócio e arquitetura do projeto atual.

5. **Tom**: Pergunte ao usuário qual o TOM que ele deseja na comunicação entre os agentes: Neutro, Sarcástico, Hostil, Cordial, Amigável ou Outro.

6. **Confirmação**:
   - Informe ao usuário que a estrutura foi convertida e a squad multidisciplinar está pronta para agir.

---

**Atenção:** Se a pasta já estiver nomeada como `.agents`, ignore o passo 1 e prossiga para a atualização das regras e inicialização.
