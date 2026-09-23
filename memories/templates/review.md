# Review — Task NNN

**Revisor:** 👑 Tech Lead · **Data:** AAAA-MM-DD · **Iteração:** 1/3
<!-- Na 3ª CHANGES REQUESTED: escalar ao usuário via PO (manager § Loops Limitados). -->

<!-- O review roda no fan-out, em paralelo ao QA e ao Security (manager § 🔀): preencha Conformidade e
     Veredito sem esperar os outros gates. A seção Join é preenchida pelo TL ao consolidar. -->

## Conformidade
<!-- Diff × spec da task, memories/guidelines.md, memories/architecture.md, memories/business.md, higiene. -->
| Dimensão | Veredito | Observação |
|---|---|---|
| Spec / DoD | ✅/❌ | |
| Guidelines | ✅/❌ | |
| Arquitetura / ADRs | ✅/❌ | |
| Regras de negócio | ✅/❌ | |
| Higiene (dead code, debug, segredos) | ✅/❌ | |

## Veredito
**✅ APPROVED | 🔁 CHANGES REQUESTED**
<!-- 1–3 linhas de fundamento. Opções na 3ª reprovação (via PO): mais um ciclo | dividir/repriorizar |
     pausar | aceitar com ressalvas registradas abaixo. -->

## Ressalvas e Aceites de Risco Ativos
<!-- Copiar de security-review.md § Aceites de Risco e task.md § Riscos Aceitos, se houver. -->
- nenhum

## Join da Verificação (preenchido pelo TL ao consolidar)
<!-- Pré-condição de entrega: sem evidência real de teste é PROIBIDO definir aprovada-para-entrega. -->
- `qa-report.md` presente com veredito APROVADO: ✅/❌
- Evidência de execução conferida (não apenas relatada): ✅ <resumo> | ❌ justificativa escrita
- `security-review.md` (quando Superfície Sensível foi tocada): ✅ | ❌ | não se aplica
- Este review: ✅ APPROVED | 🔁 CHANGES REQUESTED
- **Decisão:** `aprovada-para-entrega` | devolução consolidada ao Developer (gates a re-despachar: …)
