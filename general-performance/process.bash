#!/bin/bash

export LC_NUMERIC="en_US.UTF-8"

source ../common/common.bash

#for w in randread; do
for WORKLOAD in randread randwrite randrw; do
    printf "*********** $WORKLOAD workload *************\n"
    printf "Jobs\t4k\t16k\t64k\t1m\t2m\n"
    for NJOBS in 1 2 8 16; do
        printf "$NJOBS"
        for BLOCKSIZE in 4k 16k 64k 1m 2m; do
            IOPS_SET=()
            for RUN in 1 2 3; do
                DIR=results/run$RUN/$WORKLOAD/$BLOCKSIZE
                READ_IOPS=`awk -F ";" '{print $8}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                WRITE_IOPS=`awk -F ";" '{print $49}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                IOPS=$((READ_IOPS + WRITE_IOPS))
                IOPS_SET+=(${IOPS})

                READ_BW=`awk -F ";" '{print $7}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                WRITE_BW=`awk -F ";" '{print $48}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                BW=$((READ_BW + WRITE_BW))
                BW_SET+=(${BW})
            done
            AVG=`average IOPS_SET[@]`
            STDEV=`stdev IOPS_SET[@]`
            AVG_BW=`average BW_SET[@]`
            printf "\t%s" $AVG / $AVG_BW
            # printf "%s -> %s -> %d -> %s -> %s\n" $WORKLOAD $FEATURE $NJOBS $AVG $STDEV
        done
        printf "\n"
    done
    printf "\n"
done
