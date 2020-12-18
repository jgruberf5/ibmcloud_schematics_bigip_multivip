# resource group for the VE instance
data "ibm_resource_group" "group" {
  name = var.resource_group
}

# lookup SSH public keys by name
data "ibm_is_ssh_key" "ssh_pub_key" {
  name = var.ssh_key_name
}

# lookup compute profile by name
data "ibm_is_instance_profile" "instance_profile" {
  name = var.instance_profile
}

# create a random password if we need it
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# lookup image name for a custom image in region if we need it
data "ibm_is_image" "tmos_custom_image" {
  name = var.tmos_image_name
}

locals {
  # use the public image if the name is found
  public_image_map = {
    bigip-14-1-2-6-0-0-2-all-1slot = {
      "us-south" = "r006-f0a8cba9-1e9e-4771-87ba-20b7fd33b16a"
      "us-east"  = "r014-eccb5c62-82d9-438c-b81e-716f3506700f"
      "eu-gb"    = "r018-72ee97b8-ffeb-4427-bd2a-fc60e4d2b6b5"
      "eu-de"    = "r010-cf56a548-d5ca-4833-b0a6-bde256140d93"
      "jp-tok"   = "r022-44656c7d-427c-4e06-9253-3224cd1df827"
    }
    bigip-14-1-2-6-0-0-2-ltm-1slot = {
      "us-south" = "r006-1ca34358-b1f0-44b1-bf9a-a8bd9837a672"
      "us-east"  = "r014-3c86e0bf-1026-4400-91f6-b4256d972ed5"
      "eu-gb"    = "r018-e717281f-5bd7-4e08-8d54-7b45ddfb12c7"
      "eu-de"    = "r010-e8022107-fea9-471b-ba6c-8b8f8e130ab9"
      "jp-tok"   = "r022-c7377896-c997-495a-88f7-033f827d6d8b"
    }
    bigip-15-1-0-4-0-0-6-all-1slot = {
      "us-south" = "r006-654bca9e-8e4d-46c2-980b-c52fdd2237f4"
      "us-east"  = "r014-d73926e1-3b82-413f-aecc-36710b59cf4b"
      "eu-gb"    = "r018-e02a17f1-90bc-494b-ab66-4f3e03c08b7d"
      "eu-de"    = "r010-3a06e044-56e8-4d45-a5c2-535a7b673a94"
      "jp-tok"   = "r022-a65002eb-ad05-4d56-bcb8-2d3fa14f9834"
    }
    bigip-15-1-0-4-0-0-6-ltm-1slot = {
      "us-south" = "r006-c176a319-39e3-4f24-82a1-6dd4f2fa58dc"
      "us-east"  = "r014-e2a4cc82-d935-4f3f-9042-21f64d18232c"
      "eu-gb"    = "r018-859e47fb-40db-4d72-9da7-2de4fc78d64c"
      "eu-de"    = "r010-cd996cda-53ce-4783-9e3a-03a18b9162ff"
      "jp-tok"   = "r022-36b57097-deba-49c2-bffb-f37c61c8e713"
    }
  }
}

locals {
  # custom image takes priority over public image
  image_id = data.ibm_is_image.tmos_custom_image.id == null ? lookup(local.public_image_map[var.tmos_image_name], var.region) : data.ibm_is_image.tmos_custom_image.id
  # public image takes priority over custom image
  # image_id = lookup(lookup(local.public_image_map, var.tmos_image_name, {}), var.region, data.ibm_is_image.tmos_custom_image.id)  
  basic_auth_header_map = {
    "Authorization" = base64encode("${var.user_data_basic_auth_username}:${var.user_data_basic_auth_password}")
  }
  github_auth_header_map = {
    "Authorization" = "token ${var.user_data_github_personal_access_token}"
    "Accept"        = "application/vnd.github.v4.raw"
  }
  # user admin_password if supplied, else set a random password
  admin_password = var.tmos_admin_password == "" ? random_password.password.result : var.tmos_admin_password
  # set user_data YAML values or else set them to null for templating
  phone_home_url = var.phone_home_url == "" ? "null" : var.phone_home_url
  http_headers_1 = var.user_data_basic_auth_username == "" ? {} : local.basic_auth_header_map
  http_headers_2 = var.user_data_github_personal_access_token == "" ? local.http_headers_1 : local.github_auth_header_map

  snat_subnet_addresses_count = var.internal_snat_pool_count == 1 ? 0 : var.internal_snat_pool_count
  snat_pool_addresses = [
    for num in range(0, local.snat_subnet_addresses_count) :
    cidrhost(data.ibm_is_subnet.f5_snat_subnet_data[0].ipv4_cidr_block, num)
  ]
  snat_pool_addresses_csl        = join(",", local.snat_pool_addresses)
  virtual_subnet_addresses_count = var.external_virtual_address_count == 1 ? 0 : var.external_virtual_address_count
  virtual_service_addresses = [
    for num in range(0, local.virtual_subnet_addresses_count) :
    cidrhost(data.ibm_is_subnet.f5_vip_subnet_data[0].ipv4_cidr_block, num)
  ]
  virtual_service_addresses_csl = join(",", local.virtual_service_addresses)
}

data "http" "user_data_template" {
  url             = var.user_data_template_url
  request_headers = local.http_headers_2
}

data "template_file" "user_data" {
  template = data.http.user_data_template.body
  vars = {
    tmos_admin_password       = local.admin_password
    phone_home_url            = local.phone_home_url
    zone                      = data.ibm_is_subnet.f5_management_subnet.zone
    vpc                       = data.ibm_is_subnet.f5_management_subnet.vpc
    management_subnet_cidr    = data.ibm_is_subnet.f5_management_subnet.ipv4_cidr_block
    cluster_subnet_cidr       = data.ibm_is_subnet.f5_cluster_subnet.ipv4_cidr_block
    internal_subnet_cidr      = data.ibm_is_subnet.f5_internal_subnet.ipv4_cidr_block
    snat_pool_addresses       = "[${local.snat_pool_addresses_csl}]"
    external_subnet_cidr      = data.ibm_is_subnet.f5_external_subnet.ipv4_cidr_block
    virtual_service_addresses = "[${local.virtual_service_addresses_csl}]"
    appid                     = var.appid
  }
}

# create compute instance
resource "ibm_is_instance" "f5_ve_instance" {
  name    = var.instance_name
  image   = local.image_id
  profile = data.ibm_is_instance_profile.instance_profile.id
  primary_network_interface {
    name            = "management"
    subnet          = data.ibm_is_subnet.f5_management_subnet.id
    security_groups = [ibm_is_security_group.f5_open_sg.id]
  }
  network_interfaces {
    name            = "data-cluster"
    subnet          = data.ibm_is_subnet.f5_cluster_subnet.id
    security_groups = [ibm_is_security_group.f5_open_sg.id]
    allow_ip_spoofing = true
  }
  network_interfaces {
    name            = "data-internal"
    subnet          = data.ibm_is_subnet.f5_internal_subnet.id
    security_groups = [ibm_is_security_group.f5_open_sg.id]
    allow_ip_spoofing = true
  }
  network_interfaces {
    name            = "data-external"
    subnet          = data.ibm_is_subnet.f5_external_subnet.id
    security_groups = [ibm_is_security_group.f5_open_sg.id]
    allow_ip_spoofing = true
  }
  vpc        = data.ibm_is_subnet.f5_management_subnet.vpc
  zone       = data.ibm_is_subnet.f5_management_subnet.zone
  keys       = [data.ibm_is_ssh_key.ssh_pub_key.id]
  user_data  = data.template_file.user_data.rendered
  timeouts {
    create = "60m"
    delete = "120m"
  }
}

resource "ibm_is_vpc_routing_table_route" "injected_snat_routes" {
  count         = length(var.routing_table_ids)
  vpc           = data.ibm_is_subnet.f5_internal_subnet.vpc
  zone          = data.ibm_is_subnet.f5_internal_subnet.zone
  routing_table = var.routing_table_ids[count.index]
  action        = "deliver"
  destination   = data.ibm_is_subnet.f5_snat_subnet_data[0].ipv4_cidr_block
  next_hop      = ibm_is_instance.f5_ve_instance.network_interfaces[1].primary_ipv4_address
}

resource "ibm_is_vpc_routing_table_route" "injected_vip_routes" {
  count         = length(var.routing_table_ids)
  vpc           = data.ibm_is_subnet.f5_external_subnet.vpc
  zone          = data.ibm_is_subnet.f5_external_subnet.zone
  routing_table = var.routing_table_ids[count.index]
  action        = "deliver"
  destination   = data.ibm_is_subnet.f5_vip_subnet_data[0].ipv4_cidr_block
  next_hop      = ibm_is_instance.f5_ve_instance.network_interfaces[2].primary_ipv4_address
}

output "resource_name" {
  value = ibm_is_instance.f5_ve_instance.name
}

output "instance_id" {
  value = ibm_is_instance.f5_ve_instance.id
}

output "resource_status" {
  value = ibm_is_instance.f5_ve_instance.status
}

output "VPC" {
  value = ibm_is_instance.f5_ve_instance.vpc
}

output "image_id" {
  value = local.image_id
}
output "profile_id" {
  value = data.ibm_is_instance_profile.instance_profile.id
}

output "snat_pool_addresses" {
  value = local.snat_pool_addresses
}

output "virtual_service_addresses" {
  value = local.virtual_service_addresses
}
output "f5_phone_home_url" {
  value = var.phone_home_url
}

output "instance_name" {
  value = var.instance_name
}

output "security_group_id" {
  value = ibm_is_security_group.f5_open_sg.id
}
output "management_subnet_id" {
  value = data.ibm_is_subnet.f5_management_subnet.id
}
output "cluster_subnet_id" {
  value = data.ibm_is_subnet.f5_cluster_subnet.id
}

output "data_internal_subnet_id" {
  value = data.ibm_is_subnet.f5_internal_subnet.id
}

output "data_external_subnet_id" {
  value = data.ibm_is_subnet.f5_external_subnet.id
}

output "vpc" {
  value = data.ibm_is_subnet.f5_management_subnet.vpc
}

output "zone" {
  value = data.ibm_is_subnet.f5_management_subnet.zone
}

output "ssh_key_id" {
  value = data.ibm_is_ssh_key.ssh_pub_key.id
}
