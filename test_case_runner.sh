#!/bin/bash
TEST_NAME="$1"
INPUT_DIR="InputFiles"
EXTERNAL_DIR="ExternalFiles"
OUTPUT_DIR="outputFiles/$TEST_NAME"

mkdir -p "$OUTPUT_DIR"

echo "rm -rf bin"
echo "g++ -g -O0 -I . -o bin/interrupts interrupts.cpp"

for inputfile in "$INPUT_DIR"/*; do
    filename=$(basename "$inputfile")
    echo "Processing $filename"

    cp "$inputfile" trace.txt

    external_candidate="$EXTERNAL_DIR/${filename}_extern"
    if [ ! -f "$external_candidate" ]; then
        echo "Warning: no matching external file for $filename"
        rm trace.txt
        continue
    fi

    cp "$external_candidate" external_files.txt

    ./bin/interrupts trace.txt vector_table.txt device_table.txt external_files.txt

    if [ ! -f execution.txt ]; then
        echo "Warning: execution.txt not found for $filename"
        rm trace.txt
        rm -f external_files
        continue
    fi

    if [ ! -f system_status.txt ]; then
        echo "Warning: system_status.txt not found for $filename"
        rm trace.txt
        rm -f external_files
        continue
    fi

    out_exec="${OUTPUT_DIR}/${TEST_NAME}_${filename}_execution.txt"
    out_status="${OUTPUT_DIR}/${TEST_NAME}_${filename}_system_status.txt"

    cp execution.txt "$out_exec"
    cp system_status.txt "$out_status"

    rm trace.txt
    rm -f external_files

    echo "Saved outputs:"
    echo "  $out_exec"
    echo "  $out_status"
done
