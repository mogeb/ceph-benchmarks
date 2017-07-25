#!/bin/bash

POOL=rbd
IMAGE=image01

mkdir -p results

ceph --version > results/info
fio --version >> results/info
date >> results/info
echo >> results/info
ceph osd tree >> results/info

for run in 1 2 3; do
    for WORKLOAD in read write rw randread randwrite randrw; do
        for NJOBS in 1 2 8 16; do
            for FEATURE in rbd; do
                for BS in 4096 4127518; do
                    DIR=results/run$run/$FEATURE/$WORKLOAD

                    if [ $BS -eq 4096 ]; then
                        DIR=$DIR/iops
                    else
                        DIR=$DIR/bw
                    fi
                    RES=$DIR/summary_j${NJOBS}.csv
                    mkdir -p $DIR

                    rbd create $IMAGE --size 2048 --pool $POOL

                    if [ "$WORKLOAD" == "randread" ] || [ "$WORKLOAD" == "read" ]; then
                        rbd bench --io-type write -p $POOL $IMAGE --io-size 4096 --io-threads 1 --io-total 64M --io-pattern rand
                    fi
                    cat bench.fio.template | sed "s/#POOL#/$POOL/g" |
                        sed "s/#IMAGE#/$IMAGE/g" |
                        sed "s/#NUM_JOBS#/$NJOBS/g" |
                        sed "s/#WORKLOAD#/$WORKLOAD/g" |
                        sed "s/#IOSIZE#/$BS/g" |
                        sed "s!#LOGDIR#!$DIR!g" > /tmp/bench.fio

                    cp /tmp/bench.fio $DIR
                    echo "Starting fio: WL = $WORKLOAD BS = $BS, JOBS = $NJOBS"
                    fio --output-format=terse /tmp/bench.fio > $RES
                    echo "Done"
                    echo
                    echo
                    # cleanup
                    rbd rm -p $POOL $IMAGE
                done
            done
        done
    done # workload
done # run

tar -czvf results.tar.gz results
