variable "common_variables" {
  description = "Output of the common_variables module"
}

variable "az_region" {
  type    = string
  default = "westeurope"
}

variable "resource_group_name" {
  type = string
}

variable "network_subnet_id" {
  type = string
}

variable "sec_group_id" {
  type = string
}

variable "storage_account" {
  type = string
}

variable "iscsi_public_publisher" {
  type    = string
  default = "SUSE"
}

variable "iscsi_public_offer" {
  type    = string
  default = "SLES-SAP-BYOS"
}

variable "iscsi_public_sku" {
  type    = string
  default = "15"
}

variable "iscsi_public_version" {
  type    = string
  default = "latest"
}

variable "iscsi_srv_uri" {
  type    = string
  default = ""
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "admin_user" {
  type    = string
  default = "azadmin"
}

variable "bastion_enabled" {
  description = "Use a bastion machine to create the ssh connections"
  type        = bool
  default     = true
}

variable "bastion_host" {
  description = "Bastion host address"
  type        = string
  default     = ""
}

variable "bastion_private_key" {
  description = "Path to a SSH private key used to connect to the bastion. It must be provided if bastion is enabled"
  type        = string
  default     = ""
}

variable "iscsi_count" {
  description = "Number of iscsi machines to deploy"
  type        = number
}

variable "host_ips" {
  description = "List of ip addresses to set to the machines"
  type        = list(string)
}

variable "iscsi_disk_size" {
  description = "Disk size in GB used to create the LUNs and partitions to be served by the ISCSI service"
  type        = number
  default     = 10
}

variable "lun_count" {
  description = "Number of LUN (logical units) to serve with the iscsi server. Each LUN can be used as a unique sbd disk"
  type        = number
  default     = 3
}
