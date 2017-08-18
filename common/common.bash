
function log_configuration {
    RESULT_PATH=results
    mkdir -p $RESULT_PATH
    INFO=$RESULT_PATH/info

    date > $INFO
    echo >> $INFO
    uname -a >> $INFO
    ceph --version >> $INFO
    fio --version >> $INFO
    echo >> $INFO

    echo "ceph osd tree" >> $INFO
    ceph osd tree >> $INFO
    echo >> $INFO
    echo >> $INFO

    echo "salt '*' pillar.get roles" >> $INFO
    salt '*' pillar.get roles >> $INFO
    echo >> $INFO
    echo >> $INFO

    echo "salt '*' pillar.get ceph" >> $INFO
    salt '*' pillar.get ceph >> $INFO
    echo >> $INFO
    echo >> $INFO

    echo "salt '*' pillar.get storage" >> $INFO
    salt '*' pillar.get storage >> $INFO
    echo >> $INFO
    echo >> $INFO

    echo "ceph report" >> $INFO
    ceph report >> $INFO
    echo >> $INFO

    cp -ar /srv/pillar/ceph/proposals/ $INFO
}

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

function start_collectl {
    rawdiskf="cciss/c\d+d\d+ |hd[ab] | sd[a-z]+ |dm-\d+ |xvd[a-z] |fio[a-z]+ | vd[a-z]+ |emcpower[a-z]+ |psv\d+ |nvme[0-9]n[0-9]+p[0-9]+ "
    echo "Running rm -rf /tmp/ceph-benchmarks-run/"
    salt -C 'I@roles:storage' cmd.run 'rm -rf /tmp/ceph-benchmarks-run/'
    echo "Running mkdir /tmp/ceph-benchmarks-run/"
    salt -C 'I@roles:storage' cmd.run 'mkdir /tmp/ceph-benchmarks-run/'
    echo "Running collectl -P -s+cjDmN -i 1 --rawdskfilt "$rawdiskf" -F0 -f /tmp/ceph-benchmarks-run/"
    salt -C 'I@roles:storage' cmd.run 'collectl -P -s+cjdmN -i 1 --rawdskfilt "cciss/c\d+d\d+ |hd[ab] | sd[a-z]+ |dm-\d+ |xvd[a-z] |fio[a-z]+ | vd[a-z]+ |emcpower[a-z]+ |psv\d+ |nvme[0-9]n[0-9]+p[0-9]+ " -F0 -f /tmp/ceph-benchmarks-run/' --async
}

function stop_collectl {
    echo "Running pkill collectl"
    salt -C 'I@roles:storage' cmd.run 'pkill collectl'
}
