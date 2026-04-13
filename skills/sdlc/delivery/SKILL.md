---
name: delivery
description: Gerencia ciclo de releases, changelogs e deployments. Use para "finalizar tarefa", "fazer release", "deploy" ou "publicar versão".
---

## Workflow de Conclusão

1. **Release Build Check**: Executar `npm run build` (que aciona `tsc -b && vite build`) para garantir que o projeto compila sem erros de tipo ou de build.
2. **Versionamento**: Realizar o *bump* semântico no `package.json`.
3. **Changelog**: Atualizar o `CHANGELOG.md` com as novas implementações.
4. **Git Sync**: Executar Git flow (commit convencionais) e realizar o deploy para Firebase Hosting se necessário via `firebase deploy`.
