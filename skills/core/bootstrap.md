# Skill: Project Bootstrapper

## Gatilhos
- Execução inicial ou comando "Setup project context".

## Workflow de Adaptação
1. **Discovery**: Identifica manifestos (`package.json`, `.csproj`, `go.mod`, etc.).
2. **Memory Init**: Popula `architecture.md` com a stack e `guidelines.md` com regras de sintaxe.
3. **Skill Specialization**: Refatora comandos em `delivery.md` para a linguagem detectada, eliminando referências a outros ecossistemas.
4. **Skill Configuration**: Reorganiza os arquivos da pasta `skills` para que cada skill tenha seu próprio arquivo de configuração no padrão `SKILL.md` garantindo que cada skill esteja dentro do padrão esperado de acordo com https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/skills.md.
5. **Agents setup**: De acordo com o ambiente onde estiver rodando, configure os agents da pasta `agents` (por exemplo, se estiver no gemini CLI, crie um symlink para a pasta `.gemini/agents/` permitindo que o gemini CLI detecte os agents), também configure os agents de acordo com o formato esperado (por exemplo, no gemini CLI adicione o bloco --- com name, description, model e tools no topo de cada arquivo).
