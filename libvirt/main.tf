module "local_execution" {
  source  = "../generic_modules/local_exec"
  enabled = var.pre_deployment
}

# This locals entry is used to store the IP addresses of all the machines.
# Autogenerated addresses example based in 19.168.135.0/24
# Iscsi server: 192.168.135.4
# Monitoring: 192.168.135.5
# Hana ips: 192.168.135.10, 192.168.135.11
# Hana cluster vip: 192.168.135.12
# Hana cluster vip secondary: 192.168.135.13
# DRBD ips: 192.168.135.20, 192.168.135.21
# DRBD cluster vip: 192.168.135.22
# Netweaver ips: 192.168.135.30, 192.168.135.31, 192.168.135.32, 192.168.135.33
# Netweaver virtual ips: 192.168.135.34, 192.168.135.35, 192.168.135.36, 19.168.135.37
# If the addresses are provided by the user they will always have preference
locals {
  iscsi_ip          = var.iscsi_srv_ip != "" ? var.iscsi_srv_ip : cidrhost(local.iprange, 4)
  monitoring_srv_ip = var.monitoring_srv_ip != "" ? var.monitoring_srv_ip : cidrhost(local.iprange, 5)

  hana_ip_start              = 10
  hana_ips                   = length(var.hana_ips) != 0 ? var.hana_ips : [for ip_index in range(local.hana_ip_start, local.hana_ip_start + var.hana_count) : cidrhost(local.iprange, ip_index)]
  hana_cluster_vip           = var.hana_cluster_vip != "" ? var.hana_cluster_vip : cidrhost(local.iprange, local.hana_ip_start + var.hana_count)
  hana_cluster_vip_secondary = var.hana_cluster_vip_secondary != "" ? var.hana_cluster_vip_secondary : cidrhost(local.iprange, local.hana_ip_start + var.hana_count + 1)

  # 2 is hardcoded for drbd because we always deploy 2 machines
  drbd_ip_start    = 20
  drbd_ips         = length(var.drbd_ips) != 0 ? var.drbd_ips : [for ip_index in range(local.drbd_ip_start, local.drbd_ip_start + 2) : cidrhost(local.iprange, ip_index)]
  drbd_cluster_vip = var.drbd_cluster_vip != "" ? var.drbd_cluster_vip : cidrhost(local.iprange, local.drbd_ip_start + 2)

  netweaver_ip_start    = 30
  netweaver_count       = var.netweaver_enabled ? (var.netweaver_ha_enabled ? 4 : 2) : 0
  netweaver_ips         = length(var.netweaver_ips) != 0 ? var.netweaver_ips : [for ip_index in range(local.netweaver_ip_start, local.netweaver_ip_start + local.netweaver_count) : cidrhost(local.iprange, ip_index)]
  netweaver_virtual_ips = length(var.netweaver_virtual_ips) != 0 ? var.netweaver_virtual_ips : [for ip_index in range(local.netweaver_ip_start, local.netweaver_ip_start + local.netweaver_count) : cidrhost(local.iprange, ip_index + local.netweaver_count)]

  # Check if iscsi server has to be created
  iscsi_enabled = var.sbd_storage_type == "iscsi" && (var.hana_count > 1 && var.hana_cluster_sbd_enabled == true || (var.drbd_enabled && var.drbd_cluster_sbd_enabled == true) || (local.netweaver_count > 1 && var.netweaver_cluster_sbd_enabled == true)) ? true : false
}

module "iscsi_server" {
  source                 = "./modules/iscsi_server"
  iscsi_count            = local.iscsi_enabled == true ? 1 : 0
  source_image           = var.iscsi_source_image
  volume_name            = var.iscsi_source_image != "" ? "" : (var.iscsi_volume_name != "" ? var.iscsi_volume_name : local.generic_volume_name)
  vcpu                   = var.iscsi_vcpu
  memory                 = var.iscsi_memory
  bridge                 = "br0"
  storage_pool           = var.storage_pool
  isolated_network_id    = local.internal_network_id
  isolated_network_name  = local.internal_network_name
  host_ips               = [local.iscsi_ip]
  lun_count              = var.iscsi_lun_count
  iscsi_disk_size        = var.sbd_disk_size
  reg_code               = var.reg_code
  reg_email              = var.reg_email
  ha_sap_deployment_repo = var.ha_sap_deployment_repo
  qa_mode                = var.qa_mode
  provisioner            = var.provisioner
  background             = var.background
}

module "hana_node" {
  source                     = "./modules/hana_node"
  name                       = "hana"
  source_image               = var.hana_source_image
  volume_name                = var.hana_source_image != "" ? "" : (var.hana_volume_name != "" ? var.hana_volume_name : local.generic_volume_name)
  hana_count                 = var.hana_count
  vcpu                       = var.hana_node_vcpu
  memory                     = var.hana_node_memory
  bridge                     = "br0"
  isolated_network_id        = local.internal_network_id
  isolated_network_name      = local.internal_network_name
  storage_pool               = var.storage_pool
  host_ips                   = local.hana_ips
  hana_inst_folder           = var.hana_inst_folder
  hana_inst_media            = var.hana_inst_media
  hana_platform_folder       = var.hana_platform_folder
  hana_sapcar_exe            = var.hana_sapcar_exe
  hana_archive_file          = var.hana_archive_file
  hana_extract_dir           = var.hana_extract_dir
  hana_disk_size             = var.hana_node_disk_size
  hana_fstype                = var.hana_fstype
  hana_cluster_vip           = local.hana_cluster_vip
  hana_cluster_vip_secondary = var.hana_active_active ? local.hana_cluster_vip_secondary : ""
  ha_enabled                 = var.hana_ha_enabled
  sbd_enabled                = var.hana_cluster_sbd_enabled
  sbd_storage_type           = var.sbd_storage_type
  sbd_disk_id                = module.hana_sbd_disk.id
  iscsi_srv_ip               = module.iscsi_server.output_data.private_addresses.0
  reg_code                   = var.reg_code
  reg_email                  = var.reg_email
  reg_additional_modules     = var.reg_additional_modules
  ha_sap_deployment_repo     = var.ha_sap_deployment_repo
  qa_mode                    = var.qa_mode
  hwcct                      = var.hwcct
  scenario_type              = var.scenario_type
  provisioner                = var.provisioner
  background                 = var.background
  monitoring_enabled         = var.monitoring_enabled
}

module "drbd_node" {
  source                 = "./modules/drbd_node"
  name                   = "drbd"
  source_image           = var.drbd_source_image
  volume_name            = var.drbd_source_image != "" ? "" : (var.drbd_volume_name != "" ? var.drbd_volume_name : local.generic_volume_name)
  drbd_count             = var.drbd_enabled == true ? 2 : 0
  vcpu                   = var.drbd_node_vcpu
  memory                 = var.drbd_node_memory
  bridge                 = "br0"
  host_ips               = local.drbd_ips
  drbd_cluster_vip       = local.drbd_cluster_vip
  drbd_disk_size         = var.drbd_disk_size
  sbd_enabled            = var.drbd_cluster_sbd_enabled
  sbd_storage_type       = var.sbd_storage_type
  sbd_disk_id            = module.drbd_sbd_disk.id
  iscsi_srv_ip           = module.iscsi_server.output_data.private_addresses.0
  reg_code               = var.reg_code
  reg_email              = var.reg_email
  reg_additional_modules = var.reg_additional_modules
  ha_sap_deployment_repo = var.ha_sap_deployment_repo
  provisioner            = var.provisioner
  background             = var.background
  monitoring_enabled     = var.monitoring_enabled
  isolated_network_id    = local.internal_network_id
  isolated_network_name  = local.internal_network_name
  storage_pool           = var.storage_pool
}

module "monitoring" {
  source                 = "./modules/monitoring"
  name                   = "monitoring"
  monitoring_enabled     = var.monitoring_enabled
  source_image           = var.monitoring_source_image
  volume_name            = var.monitoring_source_image != "" ? "" : (var.monitoring_volume_name != "" ? var.monitoring_volume_name : local.generic_volume_name)
  vcpu                   = var.monitoring_vcpu
  memory                 = var.monitoring_memory
  bridge                 = "br0"
  storage_pool           = var.storage_pool
  isolated_network_id    = local.internal_network_id
  isolated_network_name  = local.internal_network_name
  monitoring_srv_ip      = local.monitoring_srv_ip
  reg_code               = var.reg_code
  reg_email              = var.reg_email
  reg_additional_modules = var.reg_additional_modules
  ha_sap_deployment_repo = var.ha_sap_deployment_repo
  provisioner            = var.provisioner
  background             = var.background
  hana_targets           = concat(local.hana_ips, var.hana_ha_enabled ? [local.hana_cluster_vip] : [local.hana_ips[0]]) # we use the vip for HA scenario and 1st hana machine for non HA to target the active hana instance
  drbd_targets           = var.drbd_enabled ? local.drbd_ips : []
  netweaver_targets      = local.netweaver_virtual_ips
}

module "netweaver_node" {
  source                    = "./modules/netweaver_node"
  netweaver_count           = local.netweaver_count
  name                      = "netweaver"
  source_image              = var.netweaver_source_image
  volume_name               = var.netweaver_source_image != "" ? "" : (var.netweaver_volume_name != "" ? var.netweaver_volume_name : local.generic_volume_name)
  vcpu                      = var.netweaver_node_vcpu
  memory                    = var.netweaver_node_memory
  bridge                    = "br0"
  storage_pool              = var.storage_pool
  isolated_network_id       = local.internal_network_id
  isolated_network_name     = local.internal_network_name
  host_ips                  = local.netweaver_ips
  virtual_host_ips          = local.netweaver_virtual_ips
  sbd_enabled               = var.netweaver_cluster_sbd_enabled
  sbd_storage_type          = var.sbd_storage_type
  shared_disk_id            = module.netweaver_shared_disk.id
  iscsi_srv_ip              = module.iscsi_server.output_data.private_addresses.0
  hana_ip                   = var.hana_ha_enabled ? local.hana_cluster_vip : element(local.hana_ips, 0)
  netweaver_product_id      = var.netweaver_product_id
  netweaver_inst_media      = var.netweaver_inst_media
  netweaver_inst_folder     = var.netweaver_inst_folder
  netweaver_extract_dir     = var.netweaver_extract_dir
  netweaver_swpm_folder     = var.netweaver_swpm_folder
  netweaver_sapcar_exe      = var.netweaver_sapcar_exe
  netweaver_swpm_sar        = var.netweaver_swpm_sar
  netweaver_sapexe_folder   = var.netweaver_sapexe_folder
  netweaver_additional_dvds = var.netweaver_additional_dvds
  netweaver_nfs_share       = var.drbd_enabled ? "${local.drbd_cluster_vip}:/HA1" : var.netweaver_nfs_share
  ha_enabled                = var.netweaver_ha_enabled
  reg_code                  = var.reg_code
  reg_email                 = var.reg_email
  reg_additional_modules    = var.reg_additional_modules
  ha_sap_deployment_repo    = var.ha_sap_deployment_repo
  provisioner               = var.provisioner
  background                = var.background
  monitoring_enabled        = var.monitoring_enabled
}
