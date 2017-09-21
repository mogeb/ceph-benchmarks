#!/bin/bash

export LC_NUMERIC="en_US.UTF-8"

source ../common/common.bash

#for w in randread; do
FIRST_COL="IOPS"
SECOND_COL="BW"
echo > out.csv
for WORKLOAD in randread randwrite randrw; do
    printf "*********** $WORKLOAD workload *************\n"
    printf "Jobs\t4k\t16k\t64k\t1m\t2m\n"
    echo "jobs,4k,,16k,,64k,,1m,,2m" >> out.csv
    echo ",$FIRST_COL,$SECOND_COL,$FIRST_COL,$SECOND_COL,$FIRST_COL,$SECOND_COL,$FIRST_COL,$SECOND_COL" >> out.csv
    for NJOBS in 1 2 8 16; do
        printf "$NJOBS"
        echo -n "$NJOBS" >> out.csv
        for BLOCKSIZE in 4k 16k 64k 1m 2m; do
            IOPS_SET=()
            BW_SET=()
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
            printf "\t%s / %s" $AVG $AVG_BW
            echo -n ",$AVG,$AVG_BW" >> out.csv
            # printf "%s -> %s -> %d -> %s -> %s\n" $WORKLOAD $FEATURE $NJOBS $AVG $STDEV
        done
        echo >> out.csv
        printf "\n"
    done
    printf "\n"
done
