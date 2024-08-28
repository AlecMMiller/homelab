cd nodes
#tofu destroy -auto-approve
#tofu apply -auto-approve
cd ../rke2-ansible
ansible-playbook -b --become-user=root -i ../inventory/hosts.yml site.yml
