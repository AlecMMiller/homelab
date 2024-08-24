cd kubespray
ansible-playbook -i ../inventory.ini --become --become-user=root -e kubeconfig_localhost=true cluster.yml
