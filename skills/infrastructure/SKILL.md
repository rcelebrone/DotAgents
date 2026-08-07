---
name: infrastructure
description: Dependências, variáveis de ambiente e sincronização de infra. Use para "auditar dependências", "atualizar pacotes" ou "sincronizar .env/README".
---

# Skill: Infrastructure (Deps + Env)

Executada pelo **Ops** (rotina) e pelo **Security** (colaboração em CVEs).

## 1. Auditoria de Dependências
- Executar o auditor nativo da stack (registrado em `memories/architecture.md` no bootstrap): `npm audit`, `pip-audit`, `cargo audit`, `bundle audit`, `mvn dependency-check`, etc.
- CVEs encontrados → repassar ao **Security** para classificação pela rubrica (Critical/High/Medium/Low) e priorização.

## 2. Upgrade Seguro
- **minor/patch:** aplicar → rodar build + testes **DEPOIS** do upgrade → falhou? reverter o lockfile e registrar o bloqueio em `memories/architecture.md § Dívida Técnica`.
- **major:** NUNCA no ciclo corrente — abrir task P2 própria, com o changelog da dependência lido e breaking changes mapeados.
- Nunca misturar atualização de dependência e código de feature no mesmo commit.

## 3. Sincronização de Ambiente (.env)
Quando o diff do ciclo introduzir variável de ambiente nova ou alterar porta/endpoint:
- Atualizar `.env.example` (apenas NOMES e placeholders — **NUNCA** o `.env` real, NUNCA valores reais).
- Atualizar a seção de variáveis do `README.md`.
- Registrar em `memories/architecture.md § Ambientes`.
Divergência entre `.env.example`, README e código é achado — reporte, não ignore.

## Restrições
- Esta skill não decide severidade de CVE (Security decide) e não faz deploy (skill `delivery`, sob o Gate do Ops).
