#!/bin/bash

# Uso:
# bash archiver_multi_data_query.sh <FROM> <TO> <PV1> [PV2 PV3 ...]

set -euo pipefail

FROM="$1"
TO="$2"
shift 2

if [[ -z "$FROM" || -z "$TO" || "$#" -eq 0 ]]; then
    echo "Uso: $0 <FROM> <TO> <PV1> [PV2 PV3 ...]"
    exit 1
fi

# Nome directory sicuro
SAFE_FROM=$(echo "$FROM" | tr ':.' '__')
SAFE_TO=$(echo "$TO" | tr ':.' '__')
OUTPUT_DIR="${SAFE_FROM}_${SAFE_TO}"

# Evita overwrite directory (auto-suffix)
BASE_DIR="$OUTPUT_DIR"
i=1
while [[ -d "$OUTPUT_DIR" ]]; do
    OUTPUT_DIR="${BASE_DIR}_$i"
    ((i++))
done

echo "Creo directory: $OUTPUT_DIR"
mkdir "$OUTPUT_DIR"

# ---- LOOP PV ----
for PV in "$@"; do
    echo "Elaboro PV: $PV"

    SAFE_PV=$(echo "$PV" | tr ':' '_')
    FILE_NAME="${OUTPUT_DIR}/${SAFE_FROM}_${SAFE_TO}_${SAFE_PV}.csv"

    URL="http://arc1:17668/retrieval/data/getData.json?pv=${PV}&from=${FROM}&to=${TO}"

    {
        echo "#timestamp,${PV}"
    curl -s "$URL" | jq -r '
    .[0].data[] |
    (.secs + (.nanos // 0)/1e9) as $t |
    "\($t | strftime("%Y-%m-%d %H:%M:%S")).\((.nanos // 0)/100000000 | round)   \(.val*1000|round/1000)"
    '
    } > "$FILE_NAME"
        

done

echo "Completato ✅"
