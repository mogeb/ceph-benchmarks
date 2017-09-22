#!/bin/bash

export LC_NUMERIC="en_US.UTF-8"

source common.bash

loadgens=("host1" "host2")

#for w in randread; do
FIRST_COL="IOPS"
SECOND_COL="BW"
echo > out.csv
echo "jobs" > out.csv
for WORKLOAD in randread randwrite randrw; do
    printf "*********** $WORKLOAD workload *************\n"
    printf "$WORKLOAD\t4k\t64k\t2m\t4m\n"
    printf "\t%8s / %8s \t%8s / %8s \t%8s / %8s \t%8s / %8s\n" $FIRST_COL $SECOND_COL $FIRST_COL $SECOND_COL $FIRST_COL $SECOND_COL $FIRST_COL $SECOND_COL
    echo "jobs,4k,,64k,,2m,,4m" >> out.csv
    echo ",$FIRST_COL,$SECOND_COL,$FIRST_COL,$SECOND_COL,$FIRST_COL,$SECOND_COL,$FIRST_COL,$SECOND_COL" >> out.csv
    for NJOBS in 1 8; do
        printf "$NJOBS"
        echo -n "$NJOBS" >> out.csv
        for BLOCKSIZE in 4k 64k 2m 4m; do
            IOPS_SET=()
            BW_SET=()
            for RUN in 1 2; do
                IOPS=0
                BW=0
                for loadgen in "${loadgens[@]}"; do
                    DIR=results/run$RUN/$WORKLOAD/$BLOCKSIZE/${NJOBS}/${loadgen}

                    READ_IOPS=`awk -F ";" '{print $8}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    WRITE_IOPS=`awk -F ";" '{print $49}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    IOPS=$((IOPS + READ_IOPS + WRITE_IOPS))
                    # echo $IOPS

                    READ_BW=`awk -F ";" '{print $7}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    WRITE_BW=`awk -F ";" '{print $48}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    BW=$((BW + READ_BW + WRITE_BW))
                done
                IOPS_SET+=(${IOPS})
                BW_SET+=(${BW})
            done
            AVG=`average IOPS_SET[@]`
            STDEV=`stdev IOPS_SET[@]`
            AVG_BW=`average BW_SET[@]`
            printf "\t%8s / %8s" $AVG $AVG_BW
            echo -n ",$AVG,$AVG_BW" >> out.csv
            # printf "%s -> %s -> %d -> %s -> %s\n" $WORKLOAD $FEATURE $NJOBS $AVG $STDEV
        done
        echo >> out.csv
        printf "\n"
    done
    printf "\n"
done
