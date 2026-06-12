#!/bin/bash

set -e

PV="$1"
FROM="$2"
TO="$3"
OUTPUT_MODE="stdout"

if [[ "$4" == "-o" ]]; then
    OUTPUT_MODE="file"
fi

if [[ -z "$PV" || -z "$FROM" || -z "$TO" ]]; then
    echo "Uso: $0 <PV> <FROM> <TO> [-o]"
    exit 1
fi

URL="http://arc1:17668/retrieval/data/getData.json?pv=${PV}&from=${FROM}&to=${TO}"

if [[ "$OUTPUT_MODE" == "file" ]]; then
    SAFE_PV=$(echo "$PV" | tr ':' '_')
    FILE_NAME="${FROM}_${TO}_${SAFE_PV}.csv"
    echo "Scrittura su file: $FILE_NAME"

    {
        echo "#timestamp,${PV}"
    curl -s "$URL" | jq -r '
    .[0].data[] |
    (.secs + (.nanos // 0)/1e9) as $t |
    "\($t | strftime("%Y-%m-%d %H:%M:%S")).\((.nanos // 0)/100000000 | round)   \(.val*1000|round/1000)"
    '
    } > "$FILE_NAME"

else
    curl -s "$URL" | jq -r '
    .[0].data[] |
    (.secs + (.nanos // 0)/1e9) as $t |
    "\($t | strftime("%Y-%m-%d %H:%M:%S")).\((.nanos // 0)/100000000 | round)   \(.val*1000|round/1000)"
    '
fi
