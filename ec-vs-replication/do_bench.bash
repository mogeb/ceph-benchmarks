#!/bin/bash

REPPOOL=reppool
ECPOOL=ecpool
IMAGE=image01

mkdir -p results

ceph --version > results/info
fio --version >> results/info
date >> results/info
echo >> results/info
echo >> results/info
echo "ceph osd tree" >> results/info
ceph osd tree >> results/info
echo >> results/info
echo >> results/info
echo "salt '*' pillar.get roles" >> results/info
salt '*' pillar.get roles >> results/info
echo >> results/info
echo >> results/info
echo "salt '*' pillar.get storage" >> results/info
salt '*' pillar.get storage >> results/info
echo >> results/info
echo >> results/info

# runs (for volatility)
for RUN in 1 2 3; do
    # patterns
    for WORKLOAD in randread randwrite randrw; do
        # enabled features
        for FEATURE in ec replication; do
            # number of jobs
            for NJOBS in 1 2 8 16; do
                DIR=results/run$RUN/$FEATURE/$WORKLOAD
                RES=$DIR/summary_j${NJOBS}.csv
                mkdir -p $DIR

                case $FEATURE in
                ec)
                    POOL=$REPPOOL
                    ceph osd pool create $POOL 12 12
                    rbd create $IMAGE --size 2048 --pool $POOL --image-feature exclusive-lock
                ;;
                replication)
                    POOL=$ECPOOL
                    ceph osd pool create $POOL 12 12 erasure
                    ceph osd pool set $POOL allow_ec_overwrites true
                    rbd create $IMAGE --size=2G --data-pool $POOL
                ;;
                esac
                if [ "$WORKLOAD" == "randread" ]; then
                rbd bench-write -p $POOL $IMAGE --io-size 4096 --io-threads 1 --io-total 64M --io-pattern rand
                fi
                mkdir -p $DIR
                cat bench.fio.template |
                    sed "s/#POOL#/$POOL/g" |
                    sed "s/#IMAGE#/$IMAGE/g" |
                    sed "s/#NUM_JOBS#/$NJOBS/g" |
                    sed "s/#WORKLOAD#/$WORKLOAD/g" |
                    sed "s!#LOGDIR#!$DIR!g"  > /tmp/bench.fio

                cp /tmp/bench.fio $DIR
                echo "Starting fio: WL = $WORKLOAD JOBS = $NJOBS"
                fio --output-format=terse /tmp/bench.fio > $RES
                echo "Done"
                echo
                echo
                # cleanup
                rbd rm -p $POOL $IMAGE
            done
        done
    done
done

tar -czvf results.tar.gz results
