#!/bin/bash

source ../common/common.bash

osds=("osd1" "osd2" "osd3" "osd4" "osd5" "osd6")

function copy_collectl_output {
    for osd in "${osds[@]}"; do
        mkdir -p $1/${osd}
        scp -r $osd:/tmp/ceph-benchmarks-run/ $1/${osd}
    done
}

# total available is 329733752 kB
#        314 GB    157 GB    78 GB    39 GB    20 GB    10 GB    5 GB    2.5 GB  1.25 GB
# for M in 329733752 164866876 82433438 41216719 20608360 10304180 5152090 2576045 1288022
for M in 329733752 164866876; do
    MEM=$(($M/1024))
    echo "Setting mem=${MEM}"
    for osd in "${osds[@]}"; do
        ssh $osd "sed -i 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"mem=${MEM}M\"/g' /etc/default/grub"
        ssh $osd "update-bootloader"
        ssh $osd "grub2-mkconfig -o /boot/grub2/grub.cfg"
        ssh $osd "reboot"
    done

    # sleep for 5 min; wait for OSDs to boot
    echo "Waiting for OSDs to boot.."
    sleep 300
    echo "Assuming OSDs booted"

    echo "Starting collectl"
    start_collectl
    echo "Collecting information"
    sleep 20
    echo "Done collecting"
    stop_collectl
    echo "Stopped collectl"
    echo "Copying everything to /tmp/all-collectl-${MEM}"
    rm -rf /tmp/all-collectl/
    copy_collectl_output /tmp/all-collectl/all-collectl-${MEM}
    echo
done

echo "All done"
