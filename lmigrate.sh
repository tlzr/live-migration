#!/bin/bash

help () {
    echo -e 'Please fill all required fields.\nAborting ...';
}

if [ $# -lt "2" ]
then
    help
    exit 1
fi

#######[ VALUES ]#########

# vm_name='vm10'
vm_name=$1
#vm_ip='10.122.26.138'
vm_ip=$2
vm_user='cirros'
vm_key='novo'
vm_n_migrations=100

##########################

compute_nodes=`nova service-list | grep nova-compute | awk -F\| '{print $4;}' | grep -o -P '[A-z0-9-]+'`

>status.txt


for i in `seq 1 $vm_n_migrations`:
do
echo "${i}:" >> status.txt

vm_host=`nova show $vm_name | grep OS-EXT-SRV-ATTR:host | awk -F\| '{print $3;}' | grep -P -o '[A-z0-9-]+'`

for j in $compute_nodes
do
    if [ $j != $vm_host ]
    then
        migrate_host=$j
        break
    fi
done

echo "Migrating to $migrate_host" >> status.txt
nova live-migration $vm_name $migrate_host

while [ `nova show $vm_name | grep OS-EXT-STS:task_state | awk -F\| '{print $3;}' | grep -P -o '[A-z0-9-]+'` == 'migrating' ]
do
    echo $i >> status.txt
    echo 'Working:' >> status.txt
    echo `date` >> status.txt
    sleep 3
done

sleep 30

echo "Test ${i} [`date`]" >> status.txt
ssh -i ${vm_key} ${vm_user}@${vm_ip} uname -a >> status.txt

done
