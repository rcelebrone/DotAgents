# Memória de Arquitetura (Raiz)

> **Nota:** este arquivo mantém as decisões arquiteturais globais, banco de dados, infraestrutura e os **Requisitos Não Funcionais**. Decisões formais têm ADR em `docs/adr/` (skill `guard`) — aqui vive o estado consolidado.
> **Fronteira:** NÃO coloque regras sistêmicas de código, sintaxe ou formatação (isso vai em `memories/guidelines.md`) nem regras de domínio ou fluxo de usuário/produto (isso vai em `memories/business.md`).
> **Arquitetura Sináptica (Otimização de Tokens):** mantenha este arquivo enxuto (~50–100 linhas) apenas com a visão macro da stack, comandos globais de build/test/deploy e ponteiros. Decisões e aprendizados de componentes/integrações específicas (ex.: "Webhook do Stripe", "Configuração do Redis", "Fila de Pagamentos") DEVEM viver em **Nós Atômicos de Memória** em `memories/implementations/<dominio>-<assunto>.md` com Header Semântico YAML e conexões sinápticas (`connections`), indexados em `memories/implementations/INDEX.md`.
> **Protocolo de atualização:** entradas datadas `[AAAA-MM-DD][Task NNN]`, append-only; em conflito, marque a antiga com `[SUPERSEDED em AAAA-MM-DD]`. Mecânica completa: skill `compound`.

## Requisitos Não Funcionais, Stack e Infra (o que sustenta o app)

- ...

## Fluxos de Dados e Decisões de Arquitetura Sistêmica (como interage)

- ...

## Resumo do Ecossistema (dependências principais)

- ...

## Modelo de Ameaças
<!-- Mantido pelo Security: superfícies do projeto, controles ativos, decisões de threat modeling. -->

- ...

## Dívida Técnica
<!-- Registrada pelo Architect: [AAAA-MM-DD][Task NNN] descrição — impacto — sugestão. O Tech Lead prioriza (P2/P3). -->

- ...

## Deploy
<!-- Preenchido no bootstrap ou pelo Ops: procedimento de deploy remoto, comando de smoke/health check,
     estratégia de rollback. SEM esta seção preenchida, deploy remoto NÃO EXISTE para a squad. -->

- ...

## Ambientes
<!-- Matriz de ambientes e variáveis (apenas NOMES, nunca valores reais). Sincronizada com .env.example e README. -->

- ...

---
**Instrução para a Squad:** consulte e atualize este arquivo nas decisões técnicas de base (Architect, Security, Ops). Requisitos não-funcionais são memória viva rigorosa deste arquivo.
