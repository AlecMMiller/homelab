cd kubespray
ansible-playbook -i ../inventory.ini --become --become-user=root cluster.yml
