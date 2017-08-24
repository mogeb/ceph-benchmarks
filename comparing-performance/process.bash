#!/bin/bash

export LC_NUMERIC="en_US.UTF-8"

source common.bash

for folder in folder1 folder2; do
    echo > out_$folder
    printf "******************************\n"
    printf "********* $folder ************\n"
    #for w in randread; do
    for WORKLOAD in randread randwrite randrw; do
        printf "*********** $WORKLOAD workload *************\n"
        printf "\t%8s \t\t%8s \t\t%8s \t\t%8s\n" "4k" "64k" "1m" "2m"
        # printf "\t%8s\n" "4k"
        echo "jobs,4k,,64k,,1m,,2m" >> out_$folder

        FIRST_LEG="IOPS"
        SECOND_LEG="BW"
        # FIRST_LEG="READ_CLAT"
        # SECOND_LEG="WRITE_CLAT"
        # FIRST_LEG="READ_SLAT"
        # SECOND_LEG="WRITE_SLAT"
        printf "\t%12s /%10s\t%12s /%10s\t%12s /%10s\t%12s /%10s\n" $FIRST_LEG $SECOND_LEG $FIRST_LEG $SECOND_LEG $FIRST_LEG $SECOND_LEG $FIRST_LEG $SECOND_LEG
        echo ",$FIRST_LEG,$SECOND_LEG,$FIRST_LEG,$SECOND_LEG,$FIRST_LEG,$SECOND_LEG,$FIRST_LEG,$SECOND_LEG" >> out_$folder
        for NJOBS in 1 8 16; do
            printf "%2s" $NJOBS
            echo -n "$NJOBS" >> out_$folder
            for BLOCKSIZE in 4k 64k 1m 2m; do
                IOPS_SET=()
                BW_SET=()
                RSLAT_AVG_SET=()
                WSLAT_AVG_SET=()
                RCLAT_AVG_SET=()
                WCLAT_AVG_SET=()
                for RUN in 1 2; do
                    DIR=$folder/run$RUN/$WORKLOAD/$BLOCKSIZE

                    if [ -d "$DIR/j$NJOBS" ] ; then
                        DIR=$DIR/j$NJOBS
                    fi

                    if [ -d "$DIR/$NJOBS" ] ; then
                        DIR=$DIR/$NJOBS
                    fi

                    READ_IOPS=`awk -F ";" '{print $8}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    WRITE_IOPS=`awk -F ";" '{print $49}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    IOPS=$((READ_IOPS + WRITE_IOPS))
                    IOPS_SET+=(${IOPS})

                    READ_BW=`awk -F ";" '{print $7}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    WRITE_BW=`awk -F ";" '{print $48}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    BW=$((READ_BW + WRITE_BW))
                    BW_SET+=(${BW})

                    RSLAT_AVG=`awk -F ";" '{print $12}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    RSLAT_AVG=$((${RSLAT_AVG}/${NJOBS}))
                    RSLAT_AVG_SET+=(${RSLAT_AVG})

                    WSLAT_AVG=`awk -F ";" '{print $53}' $DIR/summary_j${NJOBS}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
                    WSLAT_AVG=$((${WSLAT_AVG}/${NJOBS}))
                    WSLAT_AVG_SET+=(${WSLAT_AVG})

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
                AVG_RSLAT_AVG=`average RSLAT_AVG_SET[@]`
                AVG_WSLAT_AVG=`average WSLAT_AVG_SET[@]`
                printf "\t%10s / %10s" $AVG $AVG_BW
                # printf "\t%10s / %10s" $AVG_RSLAT_AVG $AVG_WSLAT_AVG
                # printf "\t%10s / %10s" $AVG_RCLAT_AVG $AVG_WCLAT_AVG
                echo -n ",$AVG,$AVG_BW" >> out_$folder
            done
            echo >> out_$folder
            printf "\n"
        done
        printf "\n"
        echo >> out_$folder
    done
done
