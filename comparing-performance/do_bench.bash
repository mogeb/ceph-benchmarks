#!/bin/bash

source ../common/common.bash

POOL=benchpool
IMAGE=image01

# log Cluster details
log_configuration

echo "Testing if pool deletion is enabled"
ceph osd pool create cephbench_foobar_testpool 12 12
if ! ceph osd pool delete cephbench_foobar_testpool cephbench_foobar_testpool --yes-i-really-really-mean-it; then
    echo "ERROR - Can't delete pool. Please make sure mon_allow_pool_delete is set to true"
    exit 1
fi


# runs (for volatility)
for RUN in 1 2; do
    for PG_NUM in 12 1024; do
        ceph osd pool create $POOL $PG_NUM $PG_NUM
        # patterns
        for WORKLOAD in randread randwrite randrw; do
            # enabled features
            for BLOCKSIZE in 4k 64k 1m 2m; do
                # number of jobs
                for NJOBS in 1 8 16; do
                    echo
                    echo "##### using librbd..."
                    echo
                    DIR=results/run$RUN/librbd/$WORKLOAD/$BLOCKSIZE
                    RES=$DIR/summary_j${NJOBS}.csv
                    if [ -f $RES ] ; then
                        echo
                        echo "$RES exists, skipping.."
                        echo
                        echo
                        continue
                    fi
                    mkdir -p $DIR

                    rbd create $IMAGE --size 2048 --pool $POOL

                    if [ "$WORKLOAD" == "randread" ]; then
                        rbd bench-write -p $POOL $IMAGE --io-size 4096 --io-threads 1 --io-total 64M --io-pattern rand
                    fi
                    cat ../common/bench.fio.librbd.template |
                        sed "s/#POOL#/$POOL/g" |
                        sed "s/#IMAGE#/$IMAGE/g" |
                        sed "s/#NUM_JOBS#/$NJOBS/g" |
                        sed "s/#WORKLOAD#/$WORKLOAD/g" |
                        sed "s/#BLOCKSIZE#/$BLOCKSIZE/g" |
                        sed "s!#LOGDIR#!$DIR!g"  > /tmp/bench.fio

                    while ceph -s | grep client\: ; do echo "Waiting for IO to settle..."; sleep 2; done

                    cp /tmp/bench.fio $DIR
                    echo "Starting librbd fio: Run $RUN, WL = $WORKLOAD, BS = $BLOCKSIZE, JOBS = $NJOBS"
                    fio --output-format=terse /tmp/bench.fio > $RES
                    echo "Done"

                    # cleanup
                    rbd rm $POOL/$IMAGE


                    echo
                    echo "##### using krbd..."
                    echo
                    DIR=results/run$RUN/krbd/$WORKLOAD/$BLOCKSIZE
                    RES=$DIR/summary_j${NJOBS}.csv
                    if [ -f $RES ] ; then
                        echo
                        echo "$RES exists, skipping.."
                        echo
                        echo
                        continue
                    fi
                    mkdir -p $DIR

                    rbd create $IMAGE --size 2048 --pool $POOL
                    rbd map --pool $POOL $IMAGE

                    if [ "$WORKLOAD" == "randread" ]; then
                        rbd bench-write -p $POOL $IMAGE --io-size 4096 --io-threads 1 --io-total 64M --io-pattern rand
                    fi
                    cat ../common/bench.fio.krbd.template |
                        sed "s/#POOL#/$POOL/g" |
                        sed "s/#IMAGE#/$IMAGE/g" |
                        sed "s/#NUM_JOBS#/$NJOBS/g" |
                        sed "s/#WORKLOAD#/$WORKLOAD/g" |
                        sed "s/#BLOCKSIZE#/$BLOCKSIZE/g" |
                        sed "s!#LOGDIR#!$DIR!g"  > /tmp/bench.fio

                    while ceph -s | grep client\: ; do echo "Waiting for IO to settle..."; sleep 2; done

                    cp /tmp/bench.fio $DIR
                    echo "Starting krbd fio: Run $RUN, WL = $WORKLOAD, BS = $BLOCKSIZE, JOBS = $NJOBS"
                    fio --output-format=terse /tmp/bench.fio > $RES
                    echo "Done"

                    # cleanup
                    rbd rm $POOL/$IMAGE
                done
            done
        done
        ceph osd pool delete $POOL $POOL --yes-i-really-really-mean-it
    done
done

tar -czvf results.tar.gz results
