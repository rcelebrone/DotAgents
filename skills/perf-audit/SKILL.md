---
name: perf-audit
description: Analisa gargalos de performance, complexidade algorítmica (Big-O) e vazamentos de memória. Use para "otimizar query", "reduzir alocação de memória" ou "auditar gargalos".
---

## Foco de Análise (Checklist)

- **Complexidade (Time/Space):** loops aninhados desnecessários (O(N²)), algoritmos de busca/ordenação ineficientes.
- **Memória:** alocações excessivas em rotas quentes, vazamento de referências, pressão de Garbage Collection.
- **I/O e Banco:** N+1 queries, ausência de paginação em grandes conjuntos, chamadas de rede síncronas bloqueantes, falta de índices.
- **Concorrência:** deadlocks, race conditions, uso inadequado de mutex/locks, subutilização de threads/assincronismo.

## Workflow

1. **Profiling Estático:** ler o arquivo/módulo alvo e mapear as áreas de maior custo computacional.
2. **Relatório:** gerar `docs/todo/<NNN-slug>/perf-report.md` dentro do ciclo ativo (achados + prova técnica/matemática da degradação). Auditoria standalone (sem ciclo ativo) → abrir task própria via Manager antes de gravar qualquer relatório.
3. **Plano:** com autorização do Tech Lead, os achados viram itens na checklist da task (cache, batching, reescrita de loops) para o Developer aplicar — sob o fluxo normal.

## Restrições
- Otimização sem medição/prova é palpite — todo achado carrega a evidência.
- Não otimizar à custa de legibilidade sem registro em task.md § Decisões Técnicas.
