cd tf
tofu apply
cd ../kubespray
ansible-playbook -i ../inventory.ini --become --become-user=root -e kube_network_plugin=cilium -e kubeconfig_localhost=true cluster.yml
