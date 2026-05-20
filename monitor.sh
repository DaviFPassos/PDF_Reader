#!/bin/bash

BASE_DIR=$(pwd)
INPUT_DIR="$BASE_DIR/data/input"
PROCESSING_DIR="$BASE_DIR/data/processing"
ARCHIVE_DIR="$BASE_DIR/data/archive"
ERROR_DIR="$BASE_DIR/data/error"

echo "===================================================="
echo " Starting DocuWatch Kernel (V5 - Direct Inode Lock)..."
echo " Monitoring folder: $INPUT_DIR"
echo "===================================================="

mkdir -p "$INPUT_DIR" "$PROCESSING_DIR" "$ARCHIVE_DIR" "$ERROR_DIR"

while true; do
    # Verify if there are any .pdf on file
    if ls "$INPUT_DIR"/*.pdf >/dev/null 2>&1; then
        
        FILE=$(ls "$INPUT_DIR"/*.pdf | head -n 1)
        FILENAME=$(basename "$FILE")
        
        SIZE1=$(stat -c %s "$FILE")
        sleep 1
        SIZE2=$(stat -c %s "$FILE")
        
        if [ "$SIZE1" -ne "$SIZE2" ]; then
            continue
        fi
        

        echo "[SHELL INFO] New PDF stabilized and ready: $FILENAME"
        CURRENT_FILE="$PROCESSING_DIR/$FILENAME"
        
        rm -f "$CURRENT_FILE"
        
        if ! mv "$FILE" "$PROCESSING_DIR"; then
            echo "[SHELL WARNING] Failed to move file. System lock detected. Retrying next loop..."
            echo "===================================================="
            sleep 2
            continue
        fi
        
        echo "[SHELL INFO] Involving Python engine..."
        python3 "$BASE_DIR/extract_intelligence.py" "$CURRENT_FILE"
        PYTHON_EXIT_CODE=$?
        
        echo "[SHELL DEBUG] Python finished with code: $PYTHON_EXIT_CODE"
        
        if [ $PYTHON_EXIT_CODE -eq 0 ]; then
            echo "[SHELL SUCCESS] Moving to Archive..."
            mv "$CURRENT_FILE" "$ARCHIVE_DIR"
        else
            echo "[SHELL ERROR] Python crashed. Moving to Error Quarantine..."
            mv "$CURRENT_FILE" "$ERROR_DIR"
        fi
        echo "===================================================="
    fi
    sleep 2
done