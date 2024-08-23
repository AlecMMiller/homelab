terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "fedora" {
  name = "fedora-${format(var.hostname_format, count.index + 1)}.qcow2"
  count = var.hosts
  pool = "default"
  source = "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2"
  format = "qcow2"
}

variable "hosts" {
  default = 2
}

variable "hostname_format" {
  type = string
  default = "node-%02d"
}

resource "libvirt_network" "cluster" {
  name = "cluster"

  addresses = ["10.17.3.0/24", "2001:db8:ca2:2::1/64"]
}

resource "libvirt_domain" "node" {
  count = var.hosts
  name = format(var.hostname_format, count.index + 1)
  vcpu = 1
  memory = 2048

  network_interface {
    network_name = "cluster"
  }

  disk {
    volume_id = element(libvirt_volume.fedora.*.id, count.index)
  }
}
