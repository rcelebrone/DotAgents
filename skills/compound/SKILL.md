---
name: compound
description: Persistência de aprendizados nas memórias vivas ao final de cada ciclo. Use para "atualizar memória", "guardar aprendizados" ou "sincronizar contexto do projeto". Executada pelo Tech Lead após o PO definir Status entregue.
---

# Skill: Compound (Memória Viva)

Executada pelo **Tech Lead** quando a task atinge Status `entregue`. Consolida o que o ciclo ensinou nas três memórias + fragmentos.

## 1. Coleta de Contexto
- Ler o diff do ciclo e o diretório da task (`task.md`, `qa-report.md`, `review.md`, `security-review.md`).
- Identificar candidatos a aprendizado: regra de negócio nova/alterada, decisão técnica, antipadrão detectado, configuração de deploy/ambiente.

## 2. Template de Entrada (obrigatório)
Toda entrada nas memórias segue o formato:

```markdown
### [AAAA-MM-DD][Task NNN] <título curto>
<aprendizado em 1–4 linhas>
Origem: docs/done/NNN-slug/
```

## 3. Regras de Escrita
- **Destino pela fronteira:** regra de domínio → `business.md` · decisão/NFR/infra → `architecture.md` · convenção/antipadrão → `guidelines.md`. Na dúvida, releia o cabeçalho de fronteira de cada arquivo.
- **Append-only:** nunca reescreva entradas antigas. Conflito com entrada existente → adicione a nova e marque a antiga com `[SUPERSEDED em AAAA-MM-DD]` (nunca apague).
- **Dedup:** antes de inserir, busque (grep) o termo-chave — se já existe entrada equivalente, atualize via SUPERSEDED ou não duplique.

## 4. Fragmentação (memories/implementations/)
Gatilho: memória global passou de ~300 linhas OU acumulou ≥3 entradas do mesmo tópico.
- Extraia o tópico para `memories/implementations/<dominio>-<topico>.md` (ex: `checkout-rules.md`, `redis-setup.md`).
- Deixe 1 linha-resumo no arquivo global apontando para o fragmento.
- **Atualize `memories/implementations/INDEX.md`** (1 linha: `arquivo.md` — resumo — `[AAAA-MM-DD]`) — sem linha no INDEX, o fragmento é invisível para a squad.

## 5. Quem lê os fragmentos
- **Developer** e **Architect:** consultam `INDEX.md` quando a task toca o domínio correspondente (passo de leitura dos protocolos deles).
- **code-review:** inclui os fragmentos relevantes na coleta de contexto.

## 6. Encerramento do Ciclo
- Remova `docs/todo/.dotagents-bypass` se existir (fecha o opt-out do ciclo).
- Informe em 1 linha ao usuário o que foi persistido (e onde).

## Restrições
- Compound NÃO altera código — apenas memórias e INDEX.
- Entrada sem data ou sem proveniência de task é violação do protocolo de memória.
