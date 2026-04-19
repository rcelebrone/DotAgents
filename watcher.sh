#!/bin/bash

# Definição dos diretórios
WATCH_DIR="./docs"
PROCESSED_DIR="$WATCH_DIR/tasks"

# Garante que a pasta de destino exista
mkdir -p "$PROCESSED_DIR"

# Nomes padronizados (Singular e Uppercase)
FILE_SPEC="SPEC.md"
FILE_PLAN="PLAN.md"
FILE_TASK="TASK.md"

echo "Monitorando $WATCH_DIR por $FILE_SPEC, $FILE_PLAN e $FILE_TASK..."

fswatch -0 "$WATCH_DIR" | while read -d "" event; do
    
    # Valida a existência dos 3 arquivos respeitando o Case Sensitive
    if [[ -f "$WATCH_DIR/$FILE_SPEC" ]] && [[ -f "$WATCH_DIR/$FILE_PLAN" ]] && [[ -f "$WATCH_DIR/$FILE_TASK" ]]; then
        
        echo "[$(date +'%H:%M:%S')] Arquivos detectados. Disparando Antigravity..."
        
        # O prompt exato formatado em uma única linha
        PROMPT="Agente, leia $WATCH_DIR/$FILE_SPEC para entender as regras, mas execute apenas a Fase 1 do $WATCH_DIR/$FILE_PLAN através das tarefas em $WATCH_DIR/$FILE_TASK."
        
        # O "</dev/null" impede que o Antigravity tente ler o pipe do fswatch
        antigravity chat "$PROMPT" </dev/null
        
        # Gera o sufixo de tempo e move os arquivos
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        
        mv "$WATCH_DIR/$FILE_SPEC" "$PROCESSED_DIR/SPEC_$TIMESTAMP.md"
        mv "$WATCH_DIR/$FILE_PLAN" "$PROCESSED_DIR/PLAN_$TIMESTAMP.md"
        mv "$WATCH_DIR/$FILE_TASK" "$PROCESSED_DIR/TASK_$TIMESTAMP.md"
        
        echo "[$(date +'%H:%M:%S')] Arquivos movidos para $PROCESSED_DIR."
        echo "---------------------------------------------------"
    fi
done
