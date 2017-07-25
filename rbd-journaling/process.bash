#!/bin/bash

function average {
    declare -a table=("${!1}")
    local size=${#table[*]}
    local result=0
    for v in ${table[@]}; do
        result=`echo "$result + $v" | bc -l`
    done
    result=`echo "$result / $size" | bc -l`
    printf "%.0f" $result
}

function stdev {
    declare -a table=("${!1}")
    local size=${#table[*]}
    local sum=0
    local sumsq=0
    for v in ${table[@]}; do
        sum=`echo "$sum + $v" | bc -l`
        sumsq=`echo "$sumsq + $v*$v" | bc -l`
    done
    local result=`echo "sqrt($sumsq/$size - ($sum/$size)^2)" | bc -l`
    printf "%.0f" $result
}


# PARSE OUTPUT
printf "Jobs\tREAD\t\tWRITE\t\tREADWRITE\t\tRANDREAD\t\tRANDWRITE\t\tRANDREADWRITE\n"
#printf "\tIOPS\tBW (Kb/s)\tIOPS\tBW (Kb/s)\tIOPS\tBW (Kb/s)\tIOPS\tBW (Kb/s)\tIOPS\tBW (Kb/s)\tIOPS\tBW (Kb/s)\n"
for WORKLOAD in read write rw randread randwrite randrw; do
    printf "*********** $WORKLOAD workload *************\n"
    printf "\tIOPS\tBW\tIOPS\tBW\tIOPS\tBW\tIOPS\tBW\tIOPS\tBW\tIOPS\tBW\n"
    for NJOBS in 1 2 8 16; do
        printf "$NJOBS"
        #for j in no_lock; do
        for FEATURE in rbd; do
            IOPS_SET=()
            BW_SET=()
            for run in 1 2 3; do
                DIR=results/run$run/$FEATURE/$WORKLOAD
                READ_IOPS=`awk -F ";" '{print $8}' $DIR/iops/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                WRITE_IOPS=`awk -F ";" '{print $49}' $DIR/iops/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`

                READ_BW=`awk -F ";" '{print $7}' $DIR/bw/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                WRITE_BW=`awk -F ";" '{print $48}' $DIR/bw/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`

                IOPS=$((READ_IOPS + WRITE_IOPS))
                IOPS_SET+=(${IOPS})

                BW=$((READ_BW + WRITE_BW))
                BW_SET+=(${BW})
            done
            AVG_IOPS=`average IOPS_SET[@]`
            STDEV_IOPS=`stdev IOPS_SET[@]`
            AVG_BW=`average BW_SET[@]`
            STDEV_BW=`stdev BW_SET[@]`
            printf "\t%s\t%s" $AVG_IOPS $AVG_BW
        done
        printf "\n"
    done
    printf "\n"
done

