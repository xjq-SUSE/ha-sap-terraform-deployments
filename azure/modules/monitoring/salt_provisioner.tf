resource "null_resource" "monitoring_provisioner" {
  count = var.common_variables["provisioner"] == "salt" && var.monitoring_enabled ? 1 : 0

  triggers = {
    monitoring_id = azurerm_virtual_machine.monitoring.0.id
  }

  connection {
    host        = element(local.provisioning_addresses, count.index)
    type        = "ssh"
    user        = var.admin_user
    private_key = file(var.common_variables["private_key_location"])

    bastion_host        = var.bastion_host
    bastion_user        = var.admin_user
    bastion_private_key = file(var.bastion_private_key)
  }

  provisioner "file" {
    content     = <<EOF
role: monitoring_srv
${var.common_variables["grains_output"]}
name_prefix: vmmonitoring
hostname: vmmonitoring
timezone: ${var.timezone}
host_ip: ${var.monitoring_srv_ip}
public_ip: ${var.bastion_enabled ? data.azurerm_network_interface.monitoring.0.private_ip_address : data.azurerm_public_ip.monitoring.0.ip_address}
hana_targets: [${join(", ", formatlist("'%s'", var.hana_targets))}]
drbd_targets: [${join(", ", formatlist("'%s'", var.drbd_targets))}]
netweaver_targets: [${join(", ", formatlist("'%s'", var.netweaver_targets))}]
network_domain: "tf.local"
EOF
    destination = "/tmp/grains"
  }
}

module "monitoring_provision" {
  source               = "../../../generic_modules/salt_provisioner"
  node_count           = var.common_variables["provisioner"] == "salt" && var.monitoring_enabled ? 1 : 0
  instance_ids         = null_resource.monitoring_provisioner.*.id
  user                 = var.admin_user
  private_key_location = var.common_variables["private_key_location"]
  bastion_host         = var.bastion_host
  bastion_private_key  = var.bastion_private_key
  public_ips           = local.provisioning_addresses
  background           = var.common_variables["background"]
}
