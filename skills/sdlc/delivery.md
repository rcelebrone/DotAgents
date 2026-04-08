# Skill: Delivery & Release

## Workflow de Conclusão
1. **Verificação de Saúde**: Acionar execução de testes de integração (`npm test`, `dotnet test`, etc - de acordo com a stack injetada pelo bootstrap). Se falhar, acionar o agente `qa-specialist`.
2. **Versionamento**: Realizar o *bump* semântico (Patch, Minor, Major) nos manifestos de pacote.
3. **Changelog**: Extrair histórico dos commits e preencher o arquivo `CHANGELOG.md` na seção `[Unreleased]`.
4. **Git Sync**: Executar o fluxo final (add, commit padronizado, push) e criar/preparar a Pull Request.
