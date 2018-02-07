#!/bin/bash
#Startup script
#This script first checks what day it is. If it's any day except Monday,
#it starts up the virts. If it's Monday, we've rebooted recently, and we 
#need to back up the virts. This script backs up files in /etc, takes an xml 
#snapshot of the current virts, and then DDs them to an external hard drive.

DAY="$(date +%u)"
DATE="$(date +%Y-%m-%d)"
BUDIR="/mnt/backup"
BS=524288
VG="VirtImgs"

#sleep 2 minutes to get everything settled
echo "Nap Time"
sleep 120

#Is it Monday?
echo "Checking day"
if [ $DAY -eq 1 ] 
then
    echo "It's Monday, time for a backup!"
    if grep -qs "$BUDIR" /proc/mounts
    then 
        echo "$BUDIR mounted, starting backup."

        #clean out old images
        rm $BUDIR/*.img.gz
        
        #make our backup directory, including /opt/virts
        mkdir -p "$BUDIR/$DATE"

        #create the xml for our virtual machines
        for i in $(virsh list --name --all)
        do 
            virsh dumpxml $i > "/usr/local/libvirt-xml/$i.xml"
        done

        #backup the backup script, /etc, and /ISO
        rsync -aR --progress /usr/local "$BUDIR/$DATE/"
        rsync -aR --progress /etc "$BUDIR/$DATE/"
        rsync -aR --progress /opt/iso "$BUDIR/$DATE/"

        #go into the volumegroup folder in /dev
        cd /dev/$VG

        #for loop through the LVs
        for j in *    
            do 
                echo $PWD/$j
                dd if=$j bs=$BS | pv | pigz --fast > $BUDIR/$j'_'$DATE.img.gz
        done
        echo "Starting virts"
    fi
else
    echo "Not Monday, starting virts"
fi

#start the virts
for k in $(virsh list --name --all)
do 
    virsh start $k
done
