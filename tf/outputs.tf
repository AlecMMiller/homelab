output "ip" {
  #value = libvirt_domain.node[*].network_interface[0].addresses[*]
  value = [
    for d in libvirt_domain.node: (
      length(d.network_interface[0].addresses) > 0 ? d.network_interface[0].addresses[0] : null
    )
  ]
}
