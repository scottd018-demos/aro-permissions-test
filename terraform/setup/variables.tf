variable "cluster_name" {
  type        = string
  default     = "my-aro-cluster"
  description = "ARO cluster name"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  default     = null
  description = "ARO resource group name"
}

variable "aro_virtual_network_cidr_block" {
  type        = string
  default     = "10.0.0.0/20"
  description = "cidr range for aro virtual network"
}

variable "aro_control_subnet_cidr_block" {
  type        = string
  default     = "10.0.0.0/23"
  description = "cidr range for aro control plane subnet"
}

variable "aro_machine_subnet_cidr_block" {
  type        = string
  default     = "10.0.2.0/23"
  description = "cidr range for aro machine subnet"
}

variable "aro_jumphost_subnet_cidr_block" {
  type        = string
  default     = "10.0.4.0/23"
  description = "cidr range for bastion / jumphost"
}

variable "outbound_type" {
  type        = string
  description = <<EOF
  Outbound Type - Loadbalancer or UserDefinedRouting
  Default "Loadbalancer"
  EOF
  default     = "Loadbalancer"

  validation {
    condition     = contains(["Loadbalancer", "UserDefinedRouting"], var.outbound_type)
    error_message = "Invalid 'outbound_type'. Only 'Loadbalancer' or 'UserDefinedRouting' are allowed."
  }
}

variable "byo_nsg" {
  type    = bool
  default = false
}

variable "aro_version" {
  type    = string
  default = "4.15.35"
}

variable "installation_type" {
  default = "cli" # api or cli
  type    = string
}

variable "miwi" {
  type    = bool
  default = false
}

variable "subscription_id" {
  type        = string
  default     = null
  description = "Explicitly use a specific Azure subscription id (defaults to the current system configuration)."
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Explicitly use a specific Azure tenant id (defaults to the current system configuration)."
}

variable "private" {
  type    = bool
  default = false
}
