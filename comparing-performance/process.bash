#!/bin/bash

export LC_NUMERIC="en_US.UTF-8"

source common.bash

for folder in ses4-sp2-results ses5-sp3-results; do
    printf "******************************\n"
    printf "********* $folder ************\n"
    #for w in randread; do
    for WORKLOAD in randread randwrite randrw; do
        printf "*********** $WORKLOAD workload *************\n"
        printf "\t%8s \t\t%8s \t\t%8s \t\t%8s\n" "4k" "64k" "1m" "2m"

        # UNCOMMENT THESE TWO LINES TO USE IOPS / BW
        # FIRST_LEG="IOPS"
        # SECOND_LEG="BW"

        # UNCOMMENT THESE TWO LINES TO USE READ_CLAT / WRITE_CLAT
        FIRST_LEG="READ_CLAT"
        SECOND_LEG="WRITE_CLAT"
        printf "\t%10s / %10s\t%10s / %10s\t%10s / %10s\t%10s / %10s\n" $FIRST_LEG $SECOND_LEG $FIRST_LEG $SECOND_LEG $FIRST_LEG $SECOND_LEG $FIRST_LEG $SECOND_LEG
        for NJOBS in 1 8 16; do
            printf "$NJOBS"
            for BLOCKSIZE in 4k 64k 1m 2m; do
                IOPS_SET=()
                BW_SET=()
                RCLAT_AVG_SET=()
                WCLAT_AVG_SET=()
                for RUN in 1 2; do
                    DIR=$folder/run$RUN/$WORKLOAD/$BLOCKSIZE
                    if [ -d "$DIR/j$NJOBS" ] ; then
                        DIR=$DIR/j$NJOBS
                    fi
                    READ_IOPS=`awk -F ";" '{print $8}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    WRITE_IOPS=`awk -F ";" '{print $49}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    IOPS=$((READ_IOPS + WRITE_IOPS))
                    IOPS_SET+=(${IOPS})

                    READ_BW=`awk -F ";" '{print $7}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    WRITE_BW=`awk -F ";" '{print $48}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    BW=$((READ_BW + WRITE_BW))
                    BW_SET+=(${BW})

                    RCLAT_AVG=`awk -F ";" '{print $16}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    RCLAT_AVG=$((${RCLAT_AVG}/${NJOBS}))
                    RCLAT_AVG_SET+=(${RCLAT_AVG})

                    WCLAT_AVG=`awk -F ";" '{print $57}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    WCLAT_AVG=$((${WCLAT_AVG}/${NJOBS}))
                    WCLAT_AVG_SET+=(${WCLAT_AVG})
                done
                AVG=`average IOPS_SET[@]`
                STDEV=`stdev IOPS_SET[@]`
                AVG_BW=`average BW_SET[@]`
                AVG_RCLAT_AVG=`average RCLAT_AVG_SET[@]`
                AVG_WCLAT_AVG=`average WCLAT_AVG_SET[@]`
                # UNCOMMENT THESE TWO LINES TO USE IOPS / BW
                # printf "\t%8s / %8s" $AVG $AVG_BW

                # UNCOMMENT THESE TWO LINES TO USE READ_CLAT / WRITE_CLAT
                printf "\t%10s / %10s" $AVG_RCLAT_AVG $AVG_WCLAT_AVG
            done
            printf "\n"
        done
        printf "\n"
    done
done
