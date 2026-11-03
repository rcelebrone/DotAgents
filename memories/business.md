# Memória de Negócio — Regras e Domínio (Requisitos Funcionais)

Este arquivo centraliza e persiste exclusivamente as regras de negócio intrínsecas e os **Requisitos Funcionais** da aplicação: "o que o sistema faz", para quem e sob quais lógicas.

> **Fronteira:** NÃO coloque tecnologias de infra ou macro-arquitetura (isso vai em `memories/architecture.md`) nem regras de convenção/clean-code de linguagem (isso vai em `memories/guidelines.md`).
> **Arquitetura Sináptica (Otimização de Tokens):** NÃO acumule regras específicas de módulos, fluxos ou features neste arquivo raiz. Mantenha aqui apenas o glossário e invariantes core (~50–100 linhas). Qualquer aprendizado de ciclo (ex.: regras do botão de pagamento, cálculo de frete, checkout) DEVE ser criado como um **Nó Atômico de Memória** em `memories/implementations/<dominio>-<assunto>.md` (usando `memories/templates/memory-node.md`) com Header Semântico YAML e conexões sinápticas (`connections`), indexado em `memories/implementations/INDEX.md`.
> **Protocolo de atualização:** entradas datadas `[AAAA-MM-DD][Task NNN]`, append-only — nunca reescreva entradas antigas; em conflito, marque a antiga com `[SUPERSEDED em AAAA-MM-DD]`. Mecânica completa: skill `compound`.

Nasce em branco em projetos novos e **é constantemente abastecido pelo Product Owner (e pela squad)** conforme as funcionalidades evoluem.

## 1. Glossário de Domínio e Terminologia

- ...

## 2. Regras de Negócio Core (o que a aplicação restringe lógica ou operacionalmente)

- ...

## 3. Direitos de Acesso e Entidades Funcionais (regras de permissão de usuário)

- ...

---
**Instrução para a Squad:** consulte e atualize este arquivo na fase de Refinamento (Product Owner). Regras de domínio orientadas ao problema do usuário vivem aqui para não se perder ao longo do desenvolvimento.
