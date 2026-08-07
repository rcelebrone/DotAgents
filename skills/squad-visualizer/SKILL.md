---
name: squad-visualizer
description: Apresenta a squad — personas, fluxo e estado atual — em markdown com diagrama Mermaid, gerado dos arquivos reais da instalação. Use para "apresentar a squad", "quem são vocês" ou "mostrar o fluxo".
---

# Skill: Squad Visualizer

Gera uma apresentação **texto/markdown** — funciona em qualquer CLI, sem servidor, sem HTML.

## Workflow

1. **Leitura dos arquivos reais** (nunca de memória): `{{AGENTS_ROOT}}/commands/manager.md` (fluxo, estados, rotas), `{{AGENTS_ROOT}}/agents/*.md` (personas ativas, missão, tier) e `{{AGENTS_ROOT}}/skills/` (inventário).

2. **Tabela de Personas:** persona · emoji · missão (1 linha) · tier · skills autorizadas (da tabela única do manager § 🧭).

3. **Diagrama do Fluxo (Mermaid):** gerar um `flowchart TD` refletindo o Fluxo Obrigatório do manager (PO → Architect → Tech Lead → Developer → QA → [Security] → TL Review → Ops → PO Validação Final → compound), com os loops "máx 3" anotados.

4. **Estado atual (opcional):** se `docs/todo/` existir, anexar o sumário de tasks por Status (reuso do passo Scan/Relatório da skill `task-tracker` — sem arquivar nada).

5. **Entrega:** responder no chat com o markdown completo. Se o usuário pedir um arquivo, gravar em `docs/squad-overview.md`.

## Restrições
- NUNCA exigir servidor local, porta ou HTML — a apresentação é texto/markdown.
- O conteúdo SEMPRE reflete os arquivos instalados naquele momento (nada hardcoded).
