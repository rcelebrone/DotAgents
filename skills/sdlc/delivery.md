# Skill: Delivery & Release

## Workflow de Conclusão
1. **Release Build Check**: Acionar comando de compilação/build para produção (e.g. `npm run build`, `dotnet publish` - de acordo com a stack). Garantir que os artefatos finais são gerados sem erro estático.
2. **Versionamento**: Realizar o *bump* semântico (Patch, Minor, Major) nos manifestos de pacote.
3. **Changelog**: Extrair histórico dos commits e preencher o arquivo `CHANGELOG.md` na seção `[Unreleased]`.
4. **Git Sync**: Executar o fluxo final (add, commit padronizado, push) e criar/preparar a Pull Request.
