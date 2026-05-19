#!/bin/bash

BASE_DIR=$(pwd)
INPUT_DIR="$BASE_DIR/data/input"
PROCESSING_DIR="$BASE_DIR/data/processing"
ARCHIVE_DIR="$BASE_DIR/data/archive"
ERROR_DIR="$BASE_DIR/data/error"

echo "===================================================="
echo " Starting DocuWatch Kernel..."
echo " Monitoring folder: $INPUT_DIR"
echo "===================================================="

while true; do
    if ls "$INPUT_DIR"/*.pdf >/dev/null 2>&1; then
        echo "[SHELL INFO] New PDF detected! Initiating triage..."
        
        FILE=$(ls "$INPUT_DIR"/*.pdf | head -n 1)
        FILENAME=$(basename "$FILE")
        
        mv "$FILE" "$PROCESSING_DIR/"
        CURRENT_FILE="$PROCESSING_DIR/$FILENAME"
        
        echo "[SHELL INFO] Invoking Python intelligence framework..."
        # Runs python and captures its exit code directly
        python3 "$BASE_DIR/extract_intelligence.py" "$CURRENT_FILE"
        PYTHON_EXIT_CODE=$?
        
        # 4. ERROR HANDLING VIA SHELL
        if [ $PYTHON_EXIT_CODE -eq 0 ]; then
            echo "[SHELL SUCCESS] Python processed file successfully. Archiving..."
            mv "$CURRENT_FILE" "$ARCHIVE_DIR/"
        else
            echo "[SHELL WARNING] Python failed to process file. Moving to Error Quarantine..."
            mv "$CURRENT_FILE" "$ERROR_DIR/"
        fi
        
        echo "===================================================="
    fi
    sleep 5
done