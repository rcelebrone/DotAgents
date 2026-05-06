# Business Rules & Domain Decisions (Functional Requirements)

Este arquivo centraliza e persiste exclusivamente as regras de negócio intrínsecas e os **Requisitos Funcionais** da aplicação. Ele mapeia "o que o sistema faz", para quem e suas lógicas de negócio.
> *Fronteira:* NÃO COLOQUE tecnologias base de infra ou macro-arquitetura (isso vai no `memorys/architecture.md`) nem regras de convenção/clean-code de linguagem (isso vai no `memorys/guidelines.md`).
> **Fragmentação:** Regras de negócio detalhadas de módulos específicos (ex: "Cálculo de Imposto Interestadual", "Fluxo de Checkout B2B") que não sejam core devem ser fragmentadas em arquivos específicos dentro de `memorys/implementations/` (ex: `memorys/implementations/checkout-rules.md`) para evitar que este arquivo se torne extenso e difícil de navegar.

Ele nasce em branco (ou com este boilerplate essencial) em novos templates e **deve ser constantemente abastecido e mantido atualizado pelo Product Owner (e pela squad)** conforme novas funcionalidades baseadas em regras do negócio evoluem.

## 1. Glossário de Domínio e Terminologia

- ...

## 2. Regras de Negócio Core (O que a aplicação restringe logica ou operacionalmente)

- ...

## 3. Direitos de Acesso e Entidades Funcionais (Regras de Permissão de Usuário)

- ...

---
**Instrução para a Squad:** Sempre consulte e atualize este arquivo nas fases de Refinamento (Product Owner). As regras de domínio estritamente orientadas ao problema do usuário devem ser atualizadas nesta memória global de negócios para não se perder ao longo do desenvolvimento.
