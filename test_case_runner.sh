#!/bin/bash
TEST_NAME="$1"
INPUT_DIR="InputFiles"
EXTERNAL_DIR="ExternalFiles"
OUTPUT_DIR="OutputFiles/$TEST_NAME"

mkdir -p "$OUTPUT_DIR"

echo "rm -rf bin"
echo "g++ -g -O0 -I . -o bin/interrupts interrupts.cpp"

extract_sections() {
    local infile="$1"

    : > trace.txt
    : > external_files.txt

    local current_program=""

    while IFS= read -r line; do

        # Program header
        if [[ "$line" =~ ^\#program([0-9]+),[[:space:]]*([0-9]+) ]]; then
            progname="program${BASH_REMATCH[1]}"
            prog_header="${progname},${BASH_REMATCH[2]}"

            # Write header to external_files
            echo "$prog_header" >> external_files.txt

            # Open program file
            current_program="${progname}.txt"
            : > "$current_program"

            continue
        fi

        # Inside a program block
        if [ -n "$current_program" ]; then
            # Stop at next program
            if [[ "$line" =~ ^\#program ]]; then
                current_program=""
                continue
            fi

            echo "$line" >> "$current_program"
            continue
        fi

        # Regular trace content
        echo "$line" >> trace.txt

    done < "$infile"
}

for inputfile in "$INPUT_DIR"/*; do
    filename=$(basename "$inputfile")
    echo "Processing $filename"

    extract_sections "$inputfile"

    external_candidate="$EXTERNAL_DIR/${filename}_extern"
    if [ -f "$external_candidate" ]; then
        cp "$external_candidate" external_files.txt
    fi

    ./bin/interrupts trace.txt vector_table.txt device_table.txt external_files.txt

    if [ ! -f execution.txt ]; then
        echo "Warning: missing execution.txt for $filename"
        continue
    fi

    if [ ! -f system_status.txt ]; then
        echo "Warning: missing system_status.txt for $filename"
        continue
    fi

    out_exec="${OUTPUT_DIR}/${TEST_NAME}_${filename}_execution.txt"
    out_status="${OUTPUT_DIR}/${TEST_NAME}_${filename}_system_status.txt"

    cp execution.txt "$out_exec"
    cp system_status.txt "$out_status"

    echo "Saved outputs:"
    echo "  $out_exec"
    echo "  $out_status"
done
