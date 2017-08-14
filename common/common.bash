
function log_configuration {
    mkdir -p results

    date >> results/info
    echo >> results/info
    ceph --version > results/info
    fio --version >> results/info
    echo >> results/info
    echo "ceph osd tree" >> results/info
    ceph osd tree >> results/info
    echo >> results/info
    echo >> results/info
    echo "salt '*' pillar.get roles" >> results/info
    salt '*' pillar.get roles >> results/info
    echo >> results/info
    echo >> results/info
    echo "salt '*' pillar.get ceph" >> results/info
    salt '*' pillar.get ceph >> results/info
    echo >> results/info
    echo >> results/info
    echo "ceph report" >> results/info
    ceph report >> results/info
    echo >> results/info

    cp -ar /srv/pillar/ceph/proposals/ results/
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
    hostname=`hostname`
    rawdiskf="cciss/c\d+d\d+ |hd[ab] | sd[a-z]+ |dm-\d+ |xvd[a-z] |fio[a-z]+ | vd[a-z]+ |emcpower[a-z]+ |psv\d+ |nvme[0-9]n[0-9]+p[0-9]+ "
    salt '*' cmd.run 'mkdir /tmp/ceph-benchmarks-run/'
    salt '*' cmd.run 'collectl -P -s+cdmN -i 1 --rawdskfilt "$rawdiskf" -F0 -f /tmp/ceph-benchmarks-run/out' --async
}

function stop_collectl {
    salt '*' cmd.run 'pkill collectl'
}
