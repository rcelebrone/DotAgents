# Memória de Diretrizes e Restrições (Raiz)

> **Nota:** memória viva preenchida pela skill `{{AGENTS_ROOT}}/skills/compound/SKILL.md`, pelo bootstrap ou por decisões da squad. Contém convenções de código, restrições e antipadrões. **Decisões arquiteturais NÃO vivem aqui** — vão em `memories/architecture.md`.
> **Fragmentação:** gatilho, nomeação (`<segmento>-<tipo>[-N].md`) e linha no `memories/implementations/INDEX.md` são determinísticos — skill `compound` § 4.
> **Protocolo de atualização:** entradas no template da skill `compound` § 2 (`Tipo` `PADRAO_VERIFICAVEL` ou `PADRAO_SEMANTICO`, `Escopo (globs)`, `Regra`, `Verify-Cmd`, `Origem`), append-only; em conflito, marque a antiga com ` [SUPERSEDED em AAAA-MM-DD]`. `PADRAO_VERIFICAVEL` exige comando executável (rodado no review); `PADRAO_SEMANTICO` registra em `N/A — <motivo>` por que não é automatizável. Validação: `dotagents-verify.sh lint`.

## Restrições e Aprendizados Técnicos

- ...

## Regras de Implementação (convenções e antipadrões)

- ...

## 🎭 Personalidade e Tom de Voz

- **Tom atual:** Neutro <!-- default; alterado no bootstrap a pedido do usuário -->
- **Diretrizes de tom:** as interações da squad refletem o tom escolhido sem comprometer a clareza técnica.

---
**Instrução para a Squad:** consulte antes de codificar; atualize ao final de cada ciclo (skill `compound`) com restrições, sintaxe e padrões aprendidos (arquitetura vai em `memories/architecture.md`).
