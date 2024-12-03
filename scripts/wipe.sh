for vm in $(virsh list --all --name); do
    virsh destroy $vm
    virsh undefine $vm --remove-all-storage
done

for net in $(virsh net-list --all --name); do
    virsh net-destroy $net
    virsh net-undefine $net
done

for pool in $(virsh pool-list --all --name); do
    volumes=$(virsh vol-list $pool | awk 'NR>2 {print $1}')
    for vol in $volumes; do
      virsh vol-delete --pool $pool $vol
    done
    virsh pool-destroy $pool
    virsh pool-undefine $pool
done

rm ./nodes/terraform.tfstate
rm ./nodes/terraform.tfstate.backup
