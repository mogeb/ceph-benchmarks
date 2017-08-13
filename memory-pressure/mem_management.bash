#!/bin/bash

osds=("172.16.250.34" "172.16.250.35" "172.16.250.36" "172.16.250.37" "172.16.250.38" "172.16.250.39")

for osd in "${osds[@]}"; do
    ssh $osd "rm ~/out"
done

# total available is 329733752 kB
#        314 GB    157 GB    78 GB    39 GB    20 GB    10 GB    5 GB    2.5 GB  1.25 GB
# for M in 329733752 164866876 82433438 41216719 20608360 10304180 5152090 2576045 1288022
for M in 329733752 164866876; do
    MEM=$(($M/1024))
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

    for osd in "${osds[@]}"; do
        ssh $osd "cat /proc/meminfo >> ~/out"
        ssh $osd "cat /etc/default/grub >> ~/out"
        ssh $osd "echo >> ~/out"
        ssh $osd "echo >> ~/out"
        ssh $osd "echo >> ~/out"
    done
done
