terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits = 4096
}

data "template_file" "inventory" {
  template = file("${path.module}/hosts.template.yml")
  vars = {
    nodes = join("\n", [
      for d in libvirt_domain.node:(
        "        \"${d.network_interface[0].addresses[0]}\":\n          node_name: \"${d.network_interface[0].hostname}\"\n          ansible_host: \"${d.network_interface[0].addresses[0]}\"\n          node_ip: \"${d.network_interface[0].addresses[0]}\""
      )
    ])
  }
}

resource "local_file" "inventory" {
  content = "${data.template_file.inventory.rendered}"
  filename = "${path.module}/../inventory/hosts.yml"
}

resource "local_sensitive_file" "pem_file" {
  filename = "${path.module}/../key.pem"
  file_permission = "600"
  content = tls_private_key.pk.private_key_pem
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "os" {
  name = "fedora-${format(var.hostname_format, count.index + 1)}.qcow2"
  count = var.hosts
  pool = libvirt_pool.os.name
  source = "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2"
  format = "qcow2"
}

variable "hosts" {
  default = 3
}

variable "hostname_format" {
  type = string
  default = "node-%02d"
}

resource "libvirt_network" "cluster" {
  name = "cluster"

  addresses = ["10.17.3.0/24"]

  dns {
    enabled = true
  }
}

resource "libvirt_pool" "os" {
  name = "os"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool"
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    public_key = "${tls_private_key.pk.public_key_openssh}"
  }
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  user_data = data.template_file.user_data.rendered
  pool = libvirt_pool.os.name
}

resource "libvirt_domain" "node" {
  depends_on = [libvirt_network.cluster]
  count = var.hosts
  name =  format(var.hostname_format, count.index + 1)
  vcpu = 4
  memory = 4096

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  network_interface {
    network_name = "${libvirt_network.cluster.name}"
    wait_for_lease = true
    hostname = format(var.hostname_format, count.index + 1)
  }

  console {
    type = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type = "pty"
    target_port = "1"
    target_type = "virtio"
  }

  disk {
    volume_id = element(libvirt_volume.os.*.id, count.index)
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}
