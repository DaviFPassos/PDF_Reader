#!/bin/bash

# Define os caminhos das pastas usando caminhos absolutos baseados no diretório atual
BASE_DIR=$(pwd)
INPUT_DIR="$BASE_DIR/data/input"
PROCESSING_DIR="$BASE_DIR/data/processing"

echo "===================================================="
echo " Starting DocuWatch Kernel..."
echo " Monitoring folder: $INPUT_DIR"
echo "===================================================="

# Loop infinito para vigiar a pasta a cada 5 segundos
while true; do
    # Verifica se existe algum arquivo .pdf na pasta de entrada
    if ls "$INPUT_DIR"/*.pdf >/dev/null 2>&1; then
        echo "[SHELL INFO] New PDF detected! Initiating triage..."
        
        # Pega o primeiro PDF encontrado
        FILE=$(ls "$INPUT_DIR"/*.pdf | head -n 1)
        FILENAME=$(basename "$FILE")
        
        echo "[SHELL INFO] Moving $FILENAME to processing queue..."
        mv "$FILE" "$PROCESSING_DIR/"
        
        echo "[SHELL INFO] Calling Python engine..."
        # Aqui o Shell chama o Python passando o caminho do arquivo como argumento
        python3 "$BASE_DIR/extract_intelligence.py" "$PROCESSING_DIR/$FILENAME"
        
        echo "----------------------------------------------------"
    fi
    sleep 5
done
