---
name: dependency-guard
description: |
  Monitora a saúde das dependências do projeto, verifica compatibilidade semântica e sugere ou aplica atualizações para precaver riscos de segurança (CVEs) e bugs de build.
---

# Dependency Guard & Security

## Gatilhos de Ativação (Triggers)
- Quando for relatado problema de compilação ou conflito com bibliotecas de terceiros.
- Comandos do usuário: "Examine as dependências" ou "Temos alguma lib vulnerável?".

## Workflow Automático
1. Detectar o package manager nativo do repositório (e.g., `npm`, `yarn`, `dotnet`, `pub`).
2. Executar comandos de auditoria correspondentes (`npm audit`, `dotnet list package --vulnerable`, `dart pub outdated`, etc).
3. Analisar saída técnica.
4. Se encontrar bugs críticos, criar tarefas ativas no escopo de `/tasks` de formato `fix/security-patch`.
5. Sugerir atualizações de minor versions, documentando o delta do refactor para manter a compilação estável.
