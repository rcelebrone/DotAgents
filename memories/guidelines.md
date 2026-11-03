# Memória de Diretrizes e Restrições (Raiz)

> **Nota:** memória viva preenchida pela skill `{{AGENTS_ROOT}}/skills/compound/SKILL.md`, pelo bootstrap ou por decisões da squad. Contém convenções globais de código e o tom de voz. **Decisões arquiteturais NÃO vivem aqui** — vão em `memories/architecture.md`.
> **Arquitetura Sináptica (Otimização de Tokens):** NUNCA acumule todas as regras e feedbacks de ciclos neste arquivo raiz. Mantenha-o enxuto (~50–100 linhas). Padrões de componentes, regras de bibliotecas, feedbacks específicos do usuário e antipadrões de módulos (ex.: "Padrão do Botão de Pagamento", "Política de Cliente HTTP") vão para **Nós Atômicos de Memória** em `memories/implementations/<dominio>-<assunto>.md` com Header Semântico YAML (`summary`, `when_to_read`, `connections`, `harness`) + linha em `memories/implementations/INDEX.md`.
> **Protocolo de atualização:** entradas datadas `[AAAA-MM-DD][Task NNN]`, append-only; em conflito, marque a antiga com `[SUPERSEDED em AAAA-MM-DD]`. Mecânica completa: skill `compound`.

## Restrições e Aprendizados Técnicos

- ...

## Regras de Implementação (convenções e antipadrões)

- ...

## 🎭 Personalidade e Tom de Voz

- **Tom atual:** Neutro <!-- default; alterado no bootstrap a pedido do usuário -->
- **Diretrizes de tom:** as interações da squad refletem o tom escolhido sem comprometer a clareza técnica.

---
**Instrução para a Squad:** consulte antes de codificar; atualize ao final de cada ciclo com restrições, sintaxe e padrões aprendidos (arquitetura vai em `memories/architecture.md`).
