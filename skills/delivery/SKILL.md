---
name: delivery
description: Fecha o ciclo de entrega local — build check, bump semântico, changelog e commit convencional. Deploy remoto somente sob a condição dupla do Ops. Use para "finalizar tarefa", "fazer release" ou "publicar versão".
---

# Skill: Delivery (Ciclo de Entrega)

Executada pelo **Ops**, somente após o Gate do Ops (checklist pré-entrega + [S/N] afirmativo — ver `{{AGENTS_ROOT}}/agents/ops.md`).

## 1. Build Check e Verificação de Integridade
Executar o comando de build da stack (registrado em `memories/architecture.md` no bootstrap: `npm run build`, `go build`, `mvn package`, etc.) **agora**, colando a saída em task.md § Evidências.
- Executar `dependency-lock` para validar paridade do lockfile e ausência de dependências não autorizadas.
- Build ou trava quebrada → parar e devolver ao fluxo (sem commit).

## 2. Versionamento Semântico
Bump no manifesto principal (`package.json`, `version.go`, `VERSION`, etc.):
- `feat` → **minor** · `fix`/`chore` → **patch** · **breaking change** → **major**, somente com confirmação explícita do usuário.

## 3. Changelog
Atualizar `CHANGELOG.md` (ou equivalente) com a entrega do ciclo, referenciando a Task NNN.

## 4. Branch Isolada, Commit Local (Conventional Commits) e Pull Request
- **Garantia de Branch Isolada:** antes de commitar, verifique que o trabalho está em uma branch dedicada `<tipo>/NNN-slug` baseada na branch principal (`main`/`master`). Se por qualquer motivo o trabalho estiver diretamente na branch principal, crie e mude imediatamente para `git checkout -b <tipo>/NNN-slug` antes do commit.
- Validar obrigatoriamente a mensagem via skill `semantic-commit-checker` (`{{AGENTS_ROOT}}/hooks/dotagents-commit-check.sh "<mensagem>"`). Exit code 1 → rejeição determinística até a mensagem ser corrigida.
- Formato: `tipo(escopo): descrição` — tipos: `feat|fix|refactor|chore|docs|test|perf`.
- Corpo referencia a task: `Task NNN`.
- Tag anotada `vX.Y.Z` opcional, conforme convenção registrada em `memories/architecture.md`.

## 5. Push da Branch e Abertura de Pull Request (PR)
- Após o commit e o fechamento do ciclo (ou após o `compound` consolidar os guardrails determinísticos na branch `<tipo>/NNN-slug`), faça o push da branch isolada para o origin (`git push -u origin <tipo>/NNN-slug`) e **gere um Pull Request (PR)** apontando para a branch principal (`main`/`master`) via CLI (`gh pr create --base main --head <tipo>/NNN-slug --title "..." --body "..."` ou link equivalente do provedor Git), contendo o resumo da entrega, evidências de testes e guardrails adicionados pelo `compound`.
- **Deploy Remoto de Produção (fronteira dura):** fazer push de branch de feature e abrir PR **não** é deploy de produção. Deploy remoto em ambiente produtivo continua exigindo a condição dupla do Ops: (a) procedimento registrado em `memories/architecture.md § Deploy` **e** (b) segunda confirmação explícita do usuário nomeando o alvo.

## 6. Encerramento
- Resultado (build + versão + commit) registrado em task.md § Evidências.
- Remova `docs/todo/.dotagents-bypass` se existir.
- Handoff: **PO (Validação Final)** — nunca direto ao compound.
