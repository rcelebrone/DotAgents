---
name: architecture-checker
description: |
  Analisa de forma estática as dependências do código escrito para garantir consistência com as camadas e convenções definidas na base (Clean/Onion Architecture).
---

# Architecture Consistency Checker

## Gatilhos de Ativação (Triggers)
- Quando uma tarefa de nível Feature for concluída ou prestes a entrar em testes.
- Quando invocado manualmente para auditar a estrutura de pastas.

## Regras Abstratas Básicas
- Camadas de **Domínio / Core** não podem ter importações de bibliotecas focadas em View/Infra/Database.
- Camadas de **Application** não devem depender do fluxo web direto (como requisições e cookies injetados cruamente).
- *Nota: Regras exatas devem ser populadas pelo `project-bootstrap` com base na semântica da stack atual do projeto.*

## Workflow
1. Execute análise estática sobre os grafos de importação ou referências de pacotes dos módulos modificados.
2. Identifique se existe "vazamento" de infraestrutura para locais indesejados.
3. Se o fluxo encontrar erro de acoplamento, gere um snippet ou diff mostrando a refatoração via injeção de dependência necessária.
