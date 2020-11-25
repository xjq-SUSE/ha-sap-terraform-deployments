resource "null_resource" "iscsi_provisioner" {
  count = var.common_variables["provisioner"] == "salt" ? var.iscsi_count : 0

  triggers = {
    iscsi_id = join(",", azurerm_virtual_machine.iscsisrv.*.id)
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
role: iscsi_srv
${var.common_variables["grains_output"]}
iscsi_srv_ip: ${element(var.host_ips, count.index)}
iscsidev: /dev/sdc
${yamlencode(
  {partitions: {for index in range(var.lun_count) :
    tonumber(index+1) => {
      start: format("%.0f%%", index*100/var.lun_count),
      end: format("%.0f%%", (index+1)*100/var.lun_count)
    }
  }}
)}

EOF
    destination = "/tmp/grains"
  }
}

module "iscsi_provision" {
  source               = "../../../generic_modules/salt_provisioner"
  node_count           = var.common_variables["provisioner"] == "salt" ? var.iscsi_count : 0
  instance_ids         = null_resource.iscsi_provisioner.*.id
  user                 = var.admin_user
  private_key_location = var.common_variables["private_key_location"]
  bastion_host         = var.bastion_host
  bastion_private_key  = var.bastion_private_key
  public_ips           = local.provisioning_addresses
  background           = var.common_variables["background"]
}
