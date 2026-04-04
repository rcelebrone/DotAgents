---
name: finish-feature
description: |
  Garante a integridade do código após o desenvolvimento, executando testes apropriados de acordo com a linguagem base, atualizando changelog e versão, e gerando relatórios de deploy/artifacts.
---

# Feature Completion & Deployment Preparation

## Gatilhos de Ativação (Triggers)
O agente deve invocar esta skill ao identificar frases como:
- "Concluí a funcionalidade X"
- "A feature Y está pronta"
- "Finalizei as tarefas da branch"
- "Pode subir as alterações"

## Workflow de Fechamento (Passo a Passo)

### Passo 1: Execução de Testes
O agente deve identificar a tecnologia atual e rodar o seu framework (e.g. `dotnet test`, `npm test`, `flutter test`, `cargo test`). Se os testes falharem, pare e reporte os erros.
*(Isso deve ser lido e restrito pela skill de bootstrap dependendo do ecossistema do seu projeto).*

### Passo 2: Geração de Executável ou Comando de Execução
Dependendo do ecossistema alvo: gerar build (`dotnet publish`, `flutter build apk`, `npm run build`, etc.). Caso seja library ou script web, apresente como validar local.

### Passo 3: Atualização do Changelog
Adicionar uma nova entrada sob a seção `[Unreleased]` ou criar build/version bump no arquivo de changelog correspondente, detalhando os commits e tasks concluídos.

### Passo 4: Incremento de Versão
Efetue o bump semântico (patch/minor) baseado no manifesto (e.g., `package.json`, `pubspec.yaml`, `.csproj`).

### Passo 5: Sincronização Remota
1. `git add .`
2. `git commit -m "chore: finalize feature and update version/changelog"`
3. `git push origin <branch>`

### Passo 6: Confirmação Final
Exibir: Relatório de testes, Localização do build, versão modificada, e link de pull request/git.
