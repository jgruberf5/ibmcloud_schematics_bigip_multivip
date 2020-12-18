data "ibm_is_subnet" "f5_management_subnet" {
  identifier = var.management_subnet_id
}

data "ibm_is_subnet" "f5_cluster_subnet" {
  identifier = var.data_cluster_subnet_id
}

data "ibm_is_subnet" "f5_internal_subnet" {
  identifier = var.data_internal_subnet_id
}

data "ibm_is_subnet" "f5_external_subnet" {
  identifier = var.data_external_subnet_id
}

// open up port security security group
resource "ibm_is_security_group" "f5_open_sg" {
  name           = "sg-${uuid()}"
  vpc            = data.ibm_is_subnet.f5_management_subnet.vpc
  resource_group = data.ibm_is_subnet.f5_management_subnet.resource_group
}

// allow all inbound
resource "ibm_is_security_group_rule" "f5_allow_inbound" {
  depends_on = [ibm_is_security_group.f5_open_sg]
  group      = ibm_is_security_group.f5_open_sg.id
  direction  = "inbound"
  remote     = "0.0.0.0/0"
}

// all all outbound
resource "ibm_is_security_group_rule" "f5_allow_outbound" {
  depends_on = [ibm_is_security_group_rule.f5_allow_inbound]
  group      = ibm_is_security_group.f5_open_sg.id
  direction  = "outbound"
  remote     = "0.0.0.0/0"
}

// SNAT Pools Subnet
resource "ibm_is_subnet" "f5_snat_subnet" {
  name                     = "f5-snat-subnet-${uuid()}"
  count                    = var.internal_snat_pool_count == 1 ? 0 : 1
  vpc                      = data.ibm_is_subnet.f5_internal_subnet.vpc
  zone                     = data.ibm_is_subnet.f5_internal_subnet.zone
  total_ipv4_address_count = var.internal_snat_pool_count
  timeouts {
    create = "60m"
    delete = "120m"
  }
}

data "ibm_is_subnet" "f5_snat_subnet_data" {
  identifier = ibm_is_subnet.f5_snat_subnet[0].id
  count      = var.internal_snat_pool_count == 1 ? 0 : 1
}

// Virtual Addresses Subnet

resource "ibm_is_subnet" "f5_vip_subnet" {
  name                     = "f5-vip-subnet-${uuid()}"
  count                    = var.external_virtual_address_count == 1 ? 0 : 1
  vpc                      = data.ibm_is_subnet.f5_external_subnet.vpc
  zone                     = data.ibm_is_subnet.f5_external_subnet.zone
  total_ipv4_address_count = var.external_virtual_address_count
  timeouts {
    create = "60m"
    delete = "120m"
  }
}

data "ibm_is_subnet" "f5_vip_subnet_data" {
  identifier = ibm_is_subnet.f5_vip_subnet[0].id
  count      = var.external_virtual_address_count == 1 ? 0 : 1
}
