#!/bin/bash

BASE_DIR=$(pwd)
INPUT_DIR="$BASE_DIR/data/input"
PROCESSING_DIR="$BASE_DIR/data/processing"
ARCHIVE_DIR="$BASE_DIR/data/archive"
ERROR_DIR="$BASE_DIR/data/error"

echo "===================================================="
echo " Starting DocuWatch Kernel (V4 - File Lock Shield)..."
echo " Monitoring folder: $INPUT_DIR"
echo "===================================================="

while true; do
    # Verifica se há arquivos .pdf na pasta de entrada
    if ls "$INPUT_DIR"/*.pdf >/dev/null 2>&1; then
        
        FILE=$(ls "$INPUT_DIR"/*.pdf | head -n 1)
        FILENAME=$(basename "$FILE")
        
        # --- TRAVA DE SEGURANÇA (Aguardar o arquivo ser totalmente liberado) ---
        # Compara o tamanho do arquivo com ele mesmo 1 segundo depois
        SIZE1=$(stat -c %s "$FILE")
        sleep 1
        SIZE2=$(stat -c %s "$FILE")
        
        if [ "$SIZE1" -ne "$SIZE2" ]; then
            # Se o tamanho mudou, o arquivo ainda está sendo gravado. Ignora nesta volta.
            continue
        fi
        # ----------------------------------------------------------------------

        echo "[SHELL INFO] New PDF stabilized and ready: $FILENAME"
        CURRENT_FILE="$PROCESSING_DIR/$FILENAME"
        
        # Remove lixo antigo se houver
        rm -f "$CURRENT_FILE"
        
        # Tenta mover. Se falhar, avisa e pula.
        if ! mv "$FILE" "$PROCESSING_DIR/"; then
            echo "[SHELL WARNING] Failed to move file. System lock detected. Retrying next loop..."
            echo "===================================================="
            sleep 2
            continue
        fi
        
        echo "[SHELL INFO] Involving Python engine..."
        python3 "$BASE_DIR/extract_intelligence.py" "$CURRENT_FILE"
        PYTHON_EXIT_CODE=$?
        
        echo "[SHELL DEBUG] Python finished with code: $PYTHON_EXIT_CODE"
        
        # Move para a pasta final baseado no sucesso do Python
        if [ $PYTHON_EXIT_CODE -eq 0 ]; then
            echo "[SHELL SUCCESS] Moving to Archive..."
            mv "$CURRENT_FILE" "$ARCHIVE_DIR/"
        else
            echo "[SHELL ERROR] Python crashed. Moving to Error Quarantine..."
            mv "$CURRENT_FILE" "$ERROR_DIR/"
        fi
        echo "===================================================="
    fi
    sleep 2
done