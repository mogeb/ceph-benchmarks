#!/bin/bash

source ../common/common.bash

POOL=benchpool
IMAGE=image01

# log Cluster details
log_configuration

osds=("blueshark1.arch.suse.de" "blueshark2.arch.suse.de" "blueshark3.arch.suse.de" "blueshark4.arch.suse.de" "blueshark5.arch.suse.de" "blueshark5.arch.suse.de" "blueshark7.arch.suse.de")

# runs (for volatility)
for RUN in 1 2 3; do
    # patterns
    for WORKLOAD in randread randwrite randrw; do
        # enabled features
        for BLOCKSIZE in 4k 16k 64k 1m 2m; do
            # number of jobs
            for NJOBS in 1 2 8 16; do
                DIR=results/run$RUN/$WORKLOAD/$BLOCKSIZE
                RES=$DIR/summary_j${NJOBS}.csv
                if [ -f $RES ] ; then
                    echo
                    echo "$RES exists, skipping.."
                    echo
                    echo
                    continue
                fi
                mkdir -p $DIR

                ceph osd pool create $POOL 12 12
                rbd create $IMAGE --size 2048 --pool $POOL

                if [ "$WORKLOAD" == "randread" ]; then
                    rbd bench-write -p $POOL $IMAGE --io-size 4096 --io-threads 1 --io-total 64M --io-pattern rand
                fi
                cat bench.fio.template |
                    sed "s/#POOL#/$POOL/g" |
                    sed "s/#IMAGE#/$IMAGE/g" |
                    sed "s/#NUM_JOBS#/$NJOBS/g" |
                    sed "s/#WORKLOAD#/$WORKLOAD/g" |
                    sed "s/#BLOCKSIZE#/$BLOCKSIZE/g" |
                    sed "s!#LOGDIR#!$DIR!g"  > /tmp/bench.fio

                cp /tmp/bench.fio $DIR
                echo
                echo "Starting collectl"
                start_collectl run$RUN_$WORKLOAD_$BLOCKSIZE
                echo
                echo "Starting fio: Run $RUN, WL = $WORKLOAD, BS = $BLOCKSIZE, JOBS = $NJOBS"
                fio --output-format=terse /tmp/bench.fio > $RES
                echo "Done"
                echo
                echo "Stopping collectl"
                stop_collectl
                echo

                for osd in "${osds[@]}"; do
                    scp $osd:/tmp/ceph-benchmarks-collectl-data/* $DIR
                done
                salt '*' cmd.run 'rm -rf /tmp/ceph-benchmarks-collectl-data/'

                # cleanup
                rbd rm $POOL/$IMAGE
            done
        done
    done
done

tar -czvf results.tar.gz results
