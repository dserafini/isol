#!/bin/bash

usage() {
    echo "Usage:"
    echo "  $0 [-s sampling_seconds] [-c] <output_file> <PV1> [PV2] ... [PVN]"
    exit 1
}

SLEEP_TIME=1
CSV_MODE=0

while getopts ":s:c" opt; do
    case ${opt} in
        s ) SLEEP_TIME=$OPTARG ;;
        c ) CSV_MODE=1 ;;
        \? ) usage ;;
    esac
done

shift $((OPTIND -1))

if [ "$#" -lt 2 ]; then
    usage
fi

OUTPUT_FILE="$1"
shift
PVS=("$@")

if [ "$CSV_MODE" -eq 1 ]; then
    SEP=","
else
    SEP=$'\t'
fi

cleanup() {
    echo ""
    echo "Stopping logger..."
    exit 0
}
trap cleanup SIGINT

# =========================
# PV CONNECTIVITY CHECK
# =========================

echo "Checking PV connectivity..."

for pv in "${PVS[@]}"; do

    CHECK=$(caget -t "$pv" 2>&1)

    if [ $? -ne 0 ] || [[ "$CHECK" == *"Invalid"* ]] || [[ -z "$CHECK" ]]; then
        echo "ERROR: Cannot connect to PV -> $pv"
        exit 1
    fi

    echo "OK: $pv"

done

echo ""

# =========================
# HEADER MANAGEMENT
# =========================

HEADER="Timestamp"
for pv in "${PVS[@]}"; do
    HEADER="${HEADER}${SEP}${pv}"
done

if [ -f "$OUTPUT_FILE" ]; then

    EXISTING_HEADER=$(head -n 1 "$OUTPUT_FILE")

    if [ "$EXISTING_HEADER" != "$HEADER" ]; then
        echo "ERROR: Existing file has different PV list."
        echo ""
        echo "Existing header:"
        echo "$EXISTING_HEADER"
        echo ""
        echo "Requested header:"
        echo "$HEADER"
        exit 1
    fi

else

    echo "$HEADER" > "$OUTPUT_FILE"

fi

# =========================
# START INFO
# =========================

START_TIME=$(date +"%Y-%m-%d %H:%M:%S")

echo "Logging started at: $START_TIME"
echo "Sampling time: ${SLEEP_TIME}s"
echo "Press Ctrl+C to stop."
echo ""

# =========================
# MAIN LOOP
# =========================

while true; do

    CYCLE_START=$(date +%s.%N)

    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S.%3N")

    VALUES=$(caget -t "${PVS[@]}" 2>/dev/null)

    LINE="$TIMESTAMP"

    INDEX=0
    while read -r VALUE; do

        if [[ -z "$VALUE" ]]; then
            VALUE="NaN"
        fi

        LINE="${LINE}${SEP}${VALUE}"
        ((INDEX++))

    done <<< "$VALUES"

    # safety if some PV didn't return
    while [ $INDEX -lt ${#PVS[@]} ]; do
        LINE="${LINE}${SEP}NaN"
        ((INDEX++))
    done

    echo "$LINE" >> "$OUTPUT_FILE"

    CYCLE_END=$(date +%s.%N)

    ELAPSED=$(echo "$CYCLE_END - $CYCLE_START" | bc -l)
    SLEEP=$(echo "$SLEEP_TIME - $ELAPSED" | bc -l)

    if (( $(echo "$SLEEP > 0" | bc -l) )); then
        sleep "$SLEEP"
    fi

done
