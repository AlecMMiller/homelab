terraform {
  required_version = ">=0.13"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_sensitive_file" "pem_file" {
  filename = "${path.module}/key.pem"
  file_permission = "600"
  content = tls_private_key.pk.private_key_pem
}

resource "local_file" "inventory" {
  content = "test"
  filename = "${path.module}/inventory.ini"
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "fedora" {
  name = "fedora-${format(var.hostname_format, count.index + 1)}.qcow2"
  count = var.hosts
  pool = libvirt_pool.fedora.name
  source = "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2"
  format = "qcow2"
}

variable "hosts" {
  default = 1
}

variable "hostname_format" {
  type = string
  default = "node-%02d"
}

resource "libvirt_network" "cluster" {
  name = "cluster"

  addresses = ["10.17.3.0/24"]
}

resource "libvirt_pool" "fedora" {
  name = "fedora"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-fedora"
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    public_key = "${tls_private_key.pk.public_key_openssh}"
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  user_data = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool = libvirt_pool.fedora.name
}

resource "libvirt_domain" "node" {
  depends_on = [libvirt_network.cluster]
  count = var.hosts
  name = format(var.hostname_format, count.index + 1)
  vcpu = 4
  memory = 4096

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  network_interface {
    network_name = "cluster"
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
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = element(libvirt_volume.fedora.*.id, count.index)
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}
