#!/bin/bash
#Shutdown script

for k in $(virsh list --name --all)
do 
    virsh shutdown $k
done
/sbin/shutdown -r now
