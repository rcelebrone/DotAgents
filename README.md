# AI Agents Template

Este projeto é um template de referência contendo skills genéricas e configurações para agentes de IA atuarem como engenheiros autônomos ou assistentes de desenvolvimento num projeto de software.

## Como Instalar e Configurar

Para utilizar este conjunto de agentes em um novo projeto, siga os seguintes passos:

1. **Copie a pasta `.agents/`** localizada na raiz deste repositório para a raiz do seu projeto destino.
2. Na sua IDE favorita (com o plugin do agente de IA que você for utilizar), envie o seguinte prompt inicial para acionar a inicialização:
   > "Por favor, execute o project-bootstrap para ajustar as skills do agente para este projeto."
3. O agente analisará sua base de código (descobrindo linguagens, frameworks de testes, e arquitetura) e modificará as skills e o `agents.md` para serem nativamente aderentes ao seu sistema.

A partir desse ponto, o agente estará preparado para atuar na sua stack específica com total precisão!
