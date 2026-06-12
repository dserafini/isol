#!/bin/bash

# codice da usare quando la corrente di FC si trova già vicino a 100 nA
# tieni un log dei tempi e degli oven set value

DESIRED_FC2_CURR_NA=100
MAXIMUM_OVEN_CURR_A=75
STEP_OVEN_CURR_A=0.1
MINIMUM_TIME_BETWEEN_OVEN_CURR_CHANGES_S=10
TIME_FOR_AVERAGE_S=2.5
TIME_FOR_FC2_CURR_READ_S=0.1

MINIMUM_OVEN_CURR_RAMP_A_PER_S=$(echo "$STEP_OVEN_CURR_A / $MINIMUM_TIME_BETWEEN_OVEN_CURR_CHANGES_S" | bc -l)
MINIMUM_OVEN_CURR_RAMP_A_PER_MIN=$(echo "$MINIMUM_OVEN_CURR_RAMP_A_PER_S * 60" | bc -l)

echo "Desired FC2 current: $DESIRED_FC2_CURR_NA nA"
echo "Maximum oven current: $MAXIMUM_OVEN_CURR_A A"
echo "Maximum oven current ramp: $MINIMUM_OVEN_CURR_RAMP_A_PER_S A/s (= $MINIMUM_OVEN_CURR_RAMP_A_PER_MIN A/min)"

SET_TIME_OVEN_CURR_S=0

# lettura iniziale
READ_OVEN_CURR_A=$(caget -t TaIoniOven_Hcps_CurrRd 2>/dev/null)

while (( $(echo "$READ_OVEN_CURR_A < $MAXIMUM_OVEN_CURR_A" | bc -l) )); do

    SUM_FC2_CURR_NA=0
    SUM_COUNTER=0

    start_time=$(date +%s.%N)
    now_time=$start_time
    last_fc_read_time=0

    while (( $(echo "$now_time - $start_time < $TIME_FOR_AVERAGE_S" | bc -l) )); do

        while (( $(echo "$now_time - $last_fc_read_time < $TIME_FOR_FC2_CURR_READ_S" | bc -l) )); do
            sleep 0.01
            now_time=$(date +%s.%N)
        done

        curr=$(caget -t FeDiagFcup02A:CurrAv 2>/dev/null)
        last_fc_read_time=$(date +%s.%N)

        if [[ -n "$curr" ]]; then
            SUM_FC2_CURR_NA=$(echo "$SUM_FC2_CURR_NA + $curr" | bc -l)
            ((SUM_COUNTER++))
        else
            echo "Failed to read current. Restarting average..."
            continue 2
        fi

        now_time=$(date +%s.%N)
    done

    AVERAGE_FC2_CURR_NA=$(echo "$SUM_FC2_CURR_NA / $SUM_COUNTER" | bc -l)

    echo "Average FC2 current: $AVERAGE_FC2_CURR_NA nA"

    if (( $(echo "$AVERAGE_FC2_CURR_NA < $DESIRED_FC2_CURR_NA" | bc -l) )); then

        NEXT_SET_TIME_OVEN_CURR_S=$(date +%s)

        if (( NEXT_SET_TIME_OVEN_CURR_S - SET_TIME_OVEN_CURR_S < MINIMUM_TIME_BETWEEN_OVEN_CURR_CHANGES_S )); then
            echo "Waiting before next oven current change..."
            sleep 1
            continue
        fi

        CURRENT_OVEN_CURR_A=$(caget -t TaIoniOven_Hcps_CurrRd 2>/dev/null)
        SET_VALUE_OVEN_CURR_A=$(echo "$CURRENT_OVEN_CURR_A + $STEP_OVEN_CURR_A" | bc -l)

        echo "Current below desired -> setting oven current to $SET_VALUE_OVEN_CURR_A A"

        caput TaIoniOven_Hcps:Curr "$SET_VALUE_OVEN_CURR_A"

        SET_TIME_OVEN_CURR_S=$NEXT_SET_TIME_OVEN_CURR_S

    else
        echo "Current above desired value. No action."
        sleep 1
    fi

    READ_OVEN_CURR_A=$(caget -t TaIoniOven_Hcps_CurrRd 2>/dev/null)

done

echo "Maximum oven current reached. Stopping ramping."
