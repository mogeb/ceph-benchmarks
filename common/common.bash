
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
    echo "salt '*' pillar.get storage" >> results/info
    salt '*' pillar.get storage >> results/info
    echo >> results/info
    echo >> results/info
    echo "ceph report" >> results/info
    ceph report >> results/info
    echo >> results/info

    cp -ar /srv/pillar/ceph/proposals/ results/
}
