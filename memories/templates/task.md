# Task NNN — <Título>

**Tipo:** feature | bug | refactor | docs | hotfix | rollback
**Status:** 🔍 em-refinamento <!-- palavra normativa (grep-ável); estados e donos: manager § 📌 Estados da Task -->
**Prioridade:** P1 | P2 | P3 · **Branch:** <tipo>/NNN-slug · **Criada:** AAAA-MM-DD
**Retomar em:** — <!-- obrigatório quando Status = pausada -->
**Retro:** — <!-- hotfix/rollback: `pendente` até existir a task de retro (ex: task NNN) -->

## Demanda
<!-- 1–3 linhas: o quê e por quê, nas palavras do usuário. -->

## User Stories
<!-- US001 — Como <persona>, quero <ação> para <valor>. Demanda técnica pode ter US única. -->
- **US001** — ...

## Gate de Completude (PO)
<!-- Respostas ESCRITAS aqui — resposta apenas no chat NÃO conta. Rota hotfix: apenas perguntas 1–3. -->
| # | Pergunta | Resposta |
|---|---|---|
| 1 | O escopo está claro (o que está dentro e fora)? | |
| 2 | O comportamento esperado está descrito? | |
| 3 | Edge cases e critério de "resolvido" foram definidos? | |
| 4 | As dependências externas foram mapeadas (APIs, serviços, dados)? | |
| 5 | As regras de negócio aplicáveis estão em `memories/business.md`? | |

**Premissas assumidas:** nenhuma
<!-- [A1] Assumi que <...> — não-bloqueante porque <...> — usuário informado em AAAA-MM-DD.
     PROIBIDO assumir premissa sobre: dinheiro/pagamentos, perda/migração de dados, segurança/auth,
     contrato de API externa → nesses temas, Status = ⛔ bloqueada até resposta do usuário. -->

## NFRs
<!-- Respostas do PO: volume/carga esperada, PII/dados sensíveis, disponibilidade/latência,
     integrações externas, restrição de prazo/custo. Insumo do Architect. -->
- ...

## DoD (Critérios de Aceite)
<!-- Um CA por comportamento verificável, formato Dado/Quando/Então. O QA valida CA por CA. -->
- [ ] **CA-1** (US001): Dado <contexto>, quando <ação>, então <resultado observável>.

## Reprodução
<!-- Somente Tipo bug/hotfix: ambiente/commit/versão, passos numerados, esperado × obtido, logs/evidência. -->

## RCA
<!-- Somente Tipo bug/hotfix (preenchido pela skill triage): causa raiz, evidência,
     hipóteses descartadas, arquivos prováveis (arquivo:linha). -->

## Notas do Architect
<!-- Impacto arquitetural, decisões (ponteiro p/ ADR em docs/adr/) e restrições — OU bloco ⚡ fast-track no Log. -->

## Checklist de Implementação (TL)
<!-- Tasks granulares: executáveis em 1 sessão, ≤ ~5 arquivos, com verificação própria. Marca: Developer. -->
- [ ] **T001** [P1] ...

### Gates
<!-- Marca: Tech Lead (QA/Security/Review, com base nos artefatos) e PO (Entrega). QA e Security NUNCA marcam. -->
- [ ] QA aprovado (`qa-report.md`)
- [ ] Security liberado (`security-review.md` | não se aplica)
- [ ] Review aprovado (`review.md`)
- [ ] Entrega fechada + DoD validado pelo PO

## Riscos Aceitos
<!-- [SEC-00X | severidade | justificativa | mitigação futura (task NNN) | expira em AAAA-MM-DD | ciente: usuário S/N] -->
- nenhum

## Evidências
<!-- Saída REAL de testes/build/lint colada aqui (Developer e Ops). "Passou" sem evidência não vale. -->

## Arquivos Alterados
| Arquivo | Mudança |
|---|---|

## Decisões Técnicas
<!-- Decisões locais da task + ponteiros para ADRs (docs/adr/NNN-*.md) e consultas ao Architect. -->
- ...

## Log
<!-- Toda transição de Status, bloco ⚡ fast-track, 🚨 violação e retomada. Formato:
     - AAAA-MM-DD HH:MM — <agente>: <status de> → <status para> — <motivo curto> -->
- AAAA-MM-DD HH:MM — PO: criada → em-refinamento — task criada a partir da demanda.
