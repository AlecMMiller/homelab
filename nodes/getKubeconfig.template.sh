ssh -i key.pem rancher@${host} "sudo cat /etc/rancher/rke2/rke2.yaml" | sed -e "s/127.0.0.1/${host}/" > kubeconfig.yml
