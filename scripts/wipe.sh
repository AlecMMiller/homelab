for vm in $(virsh list --all --name); do
    virsh undefine $vm --remove-all-storage
done

for net in $(virsh net-list --all --name); do
    virsh net-destroy $net
    virsh net-undefine $net
done

for pool in $(virsh pool-list --all --name); do
    virsh pool-destroy $pool
    virsh pool-undefine $pool
done

rm ./nodes/terraform.tfstate
rm ./nodes/terraform.tfstate.backup
