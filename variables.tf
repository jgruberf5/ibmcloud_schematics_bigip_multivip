##################################################################################
# region - The VPC region to instatiate the F5 BIG-IP instance
##################################################################################
variable "region" {
  type        = string
  default     = "us-south"
  description = "The VPC region to instatiate the F5 BIG-IP instance"
}
# Present for CLI testng
#variable "api_key" {
#  type        = string
#  default     = ""
#  description = "IBM Public Cloud API KEY"
#}

##################################################################################
# resource_group - The IBM Cloud resource group to create the F5 BIG-IP instance
##################################################################################
variable "resource_group" {
  type        = string
  default     = "default"
  description = "The IBM Cloud resource group to create the F5 BIG-IP instance"
}

##################################################################################
# instance_name - The name of the F5 BIG-IP instance
##################################################################################
variable "instance_name" {
  type        = string
  default     = "f5-ve-01"
  description = "The VPC Instance name"
}

##################################################################################
# tmos_image_name - The name of VPC image to use for the F5 BIG-IP instnace
##################################################################################
variable "tmos_image_name" {
  type        = string
  default     = "bigip-15-1-2-0-0-9-ltm-1slot-us-south"
  description = "The image to be used when provisioning the F5 BIG-IP instance"
}

##################################################################################
# instance_profile - The name of the VPC profile to use for the F5 BIG-IP instnace
##################################################################################
variable "instance_profile" {
  type        = string
  default     = "cx2-2x4"
  description = "The resource profile to be used when provisioning the F5 BIG-IP instance"
}

##################################################################################
# ssh_key_name - The name of the public SSH key to be used when provisining F5 BIG-IP
##################################################################################
variable "ssh_key_name" {
  type        = string
  default     = ""
  description = "The name of the public SSH key (VPC Gen 2 SSH Key) to be used when provisioning the F5 BIG-IP instance"
}


##################################################################################
# tmos_admin_password - The password for the built-in admin F5 BIG-IP user
##################################################################################
variable "tmos_admin_password" {
  type        = string
  default     = ""
  description = "admin account password for the F5 BIG-IP instance"
}

##################################################################################
# management_subnet_id - The VPC subnet ID for the F5 BIG-IP management interface
##################################################################################
variable "management_subnet_id" {
  type        = string
  default     = null
  description = "Required VPC Gen2 subnet ID for the F5 BIG-IP management network"
}

##################################################################################
# data_cluster_subnet_id - The VPC subnet ID for F5 BIG-IP cluster sync
##################################################################################
variable "data_cluster_subnet_id" {
  type        = string
  default     = ""
  description = "Required VPC Gen2 subnet ID for the F5 BIG-IP cluster network"
}

##################################################################################
# data_internal_subnet_id - The VPC subnet ID for the F5 BIG-IP internal interface
##################################################################################
variable "data_internal_subnet_id" {
  type        = string
  default     = ""
  description = "Required VPC Gen2 subnet ID for the F5 BIG-IP internal network"
}

##################################################################################
# internal_snat_pool_count - SNAT pool count to allocate on the internal network
##################################################################################
variable "internal_snat_pool_count" {
  type        = number
  default     = 1
  description = "Can be 1 (Automap), 2 (/31), 4 (/30), 8 (/29), 16 (/28)"
  validation {
    condition = contains([1,2,4,6,8,16], var.internal_snat_pool_count)
    error_message = "internal_snat_pool_count can be 1 (automap), 2, 4, 8, 16"
  }
}

##################################################################################
# data_external_subnet_id - The VPC subnet ID for the F5 BIG-IP external interface
##################################################################################
variable "data_external_subnet_id" {
  type        = string
  default     = ""
  description = "Required VPC Gen2 subnet ID for the F5 BIG-IP external network"
}

##################################################################################
# external_virtual_address_count - VIP count to allocate on the external network
##################################################################################
variable "external_virtual_address_count" {
  type        = number
  default     = 1
  description = "Can be 1 (SelfIP), 2 (/31), 4 (/30), 8 (/29), 16 (/28)"
  validation {
    condition = contains([1,2,4,6,8,16], var.external_virtual_address_count)
    error_message = "external_virtual_address_count can be 1 (automap), 2, 4, 8, 16"
  }
}

##################################################################################
# routing_table_ids - Routing tables to update with VIP and SNAT subnet SelfIPs
##################################################################################
variable "routing_table_ids" {
  type = list(string)
  default = []
}

##################################################################################
# phone_home_url - The web hook URL to POST status to when F5 BIG-IP onboarding completes
##################################################################################
variable "phone_home_url" {
  type        = string
  default     = ""
  description = "The URL to POST status when BIG-IP is finished onboarding"
}
variable "appid" {
  type = string
  default = ""
  description = "Extra metadata key to include in phone_home_url call"
}

##################################################################################
# schematic template for user_data
##################################################################################
variable "user_data_template_url" {
  default     = ""
  description = "The terraform template source for phone_home_url_metadata"
}
variable "user_data_basic_auth_username" {
  default     = ""
  description = "Basic auth username to aquire the user_data"
}
variable "user_data_basic_auth_password" {
  default     = ""
  description = "Basic auth password to aquire the user_data"
}
variable "user_data_github_personal_access_token" {
  default     = ""
  description = "Github personal access token to aquire the user_data"
}
