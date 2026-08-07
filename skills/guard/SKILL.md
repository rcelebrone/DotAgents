---
name: guard
description: Automatiza ADRs (Architecture Decision Records) e verifica conformidade arquitetural do diff. Use para "criar ADR", "validar arquitetura" ou "checar padrões".
---

# Skill: Guard (ADRs + Conformidade)

Executada pelo **Architect** (criação de ADRs, verificação de conformidade) e consultada pelo **Security** (decisões com impacto de segurança).

## 1. Quando criar um ADR
- Mudança de stack ou introdução de nova tecnologia.
- Nova integração externa ou novo componente estrutural.
- Adoção/alteração de padrão arquitetural (camadas, mensageria, cache).
- Aceite de risco arquitetural relevante.
Mudança sem decisão nova NÃO gera ADR (evite ruído — é o fast-track ⚡ do Architect).

## 2. Template de ADR (obrigatório)
Arquivo: `docs/adr/NNN-titulo-kebab.md` (NNN sequencial próprio de `docs/adr/`).

```markdown
# ADR NNN — <Título da Decisão>

**Status:** Proposta | Aceita | Substituída por ADR NNN | Obsoleta
**Data:** AAAA-MM-DD · **Task de origem:** NNN

## Contexto
<problema/força que motivou a decisão>

## Decisão
<a decisão, no imperativo>

## Alternativas Consideradas
- <alternativa> — <por que foi descartada>

## Consequências
- Positivas: ...
- Negativas / custos aceitos: ...
```

Após criar/atualizar um ADR **Aceita**, refletir o estado consolidado em `memories/architecture.md`.

## 3. Verificação de Conformidade (Consistency Check)
Método, na ordem:
1. Ler os ADRs com Status **Aceita** + `memories/architecture.md`.
2. Mapear imports/dependências dos arquivos do diff.
3. Checar violações das fronteiras declaradas (ex: domínio importando infraestrutura; camada X acessando Y sem passar por Z; dependência nova não registrada).
4. Saída: lista `conforme / violação` com `arquivo:linha` + qual ADR/decisão foi violada — insumo direto para o review do Tech Lead.

## Restrições
- Guard NÃO faz RCA de bugs (skill `triage`) nem auditoria de vulnerabilidades (skill `security-audit`).
- ADR sem Alternativas Consideradas está incompleto.
