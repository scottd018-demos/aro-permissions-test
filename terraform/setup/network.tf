locals {
  name_prefix = var.cluster_name
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.aro_virtual_network_cidr_block]
}

resource "azurerm_subnet" "control_plane_subnet" {
  name                              = "${local.name_prefix}-cp-subnet"
  resource_group_name               = azurerm_resource_group.main.name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = [var.aro_control_subnet_cidr_block]
  private_endpoint_network_policies = "Disabled"
  service_endpoints                 = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
}

resource "azurerm_subnet" "machine_subnet" {
  name                              = "${local.name_prefix}-machine-subnet"
  resource_group_name               = azurerm_resource_group.main.name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = [var.aro_machine_subnet_cidr_block]
  private_endpoint_network_policies = "Disabled"
  service_endpoints                 = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
}

resource "azurerm_network_security_group" "aro" {
  count = var.byo_nsg ? 1 : 0

  name                = "${local.name_prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

// TODO: lockdown for private clusters
resource "azurerm_network_security_rule" "aro_inbound_api" {
  count = var.byo_nsg ? 1 : 0

  name                        = "${local.name_prefix}-inbound-api"
  network_security_group_name = azurerm_network_security_group.aro[0].name
  resource_group_name         = azurerm_resource_group.main.name
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6443"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
}

// TODO: lockdown for private clusters
resource "azurerm_network_security_rule" "aro_inbound_http" {
  count = var.byo_nsg ? 1 : 0

  name                        = "${local.name_prefix}-inbound-http"
  network_security_group_name = azurerm_network_security_group.aro[0].name
  resource_group_name         = azurerm_resource_group.main.name
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
}

// TODO: lockdown for private clusters
resource "azurerm_network_security_rule" "aro_inbound_https" {
  count = var.byo_nsg ? 1 : 0

  name                        = "${local.name_prefix}-inbound-https"
  network_security_group_name = azurerm_network_security_group.aro[0].name
  resource_group_name         = azurerm_resource_group.main.name
  priority                    = 501
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "aro_inbound_ssh" {
  count = var.byo_nsg ? 1 : 0

  name                        = "${local.name_prefix}-inbound-ssh"
  network_security_group_name = azurerm_network_security_group.aro[0].name
  resource_group_name         = azurerm_resource_group.main.name
  priority                    = 502
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "control_plane" {
  count = var.byo_nsg ? 1 : 0

  subnet_id                 = azurerm_subnet.control_plane_subnet.id
  network_security_group_id = azurerm_network_security_group.aro[0].id
}

resource "azurerm_subnet_network_security_group_association" "machine" {
  count = var.byo_nsg ? 1 : 0

  subnet_id                 = azurerm_subnet.machine_subnet.id
  network_security_group_id = azurerm_network_security_group.aro[0].id
}

resource "azurerm_public_ip" "nat_gateway" {
  count = var.outbound_type == "UserDefinedRouting" ? 1 : 0

  name                = "${local.name_prefix}-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "aro" {
  count = var.outbound_type == "UserDefinedRouting" ? 1 : 0

  name                = "${local.name_prefix}-natgw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "aro" {
  count = var.outbound_type == "UserDefinedRouting" ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.aro[0].id
  public_ip_address_id = azurerm_public_ip.nat_gateway[0].id
}

resource "azurerm_route_table" "aro" {
  count = var.outbound_type == "UserDefinedRouting" ? 1 : 0

  name                = "${local.name_prefix}-rt"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  route {
    name           = "${local.name_prefix}-default-udr"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_nat_gateway_association" "control_plane" {
  count = var.outbound_type == "UserDefinedRouting" ? 1 : 0

  subnet_id      = azurerm_subnet.control_plane_subnet.id
  nat_gateway_id = azurerm_nat_gateway.aro[0].id
}

resource "azurerm_subnet_nat_gateway_association" "machine" {
  count = var.outbound_type == "UserDefinedRouting" ? 1 : 0

  subnet_id      = azurerm_subnet.machine_subnet.id
  nat_gateway_id = azurerm_nat_gateway.aro[0].id
}

resource "azurerm_subnet_route_table_association" "control_plane" {
  count = var.outbound_type == "UserDefinedRouting" ? 1 : 0

  subnet_id      = azurerm_subnet.control_plane_subnet.id
  route_table_id = azurerm_route_table.aro[0].id
}

resource "azurerm_subnet_route_table_association" "machine" {
  count = var.outbound_type == "UserDefinedRouting" ? 1 : 0

  subnet_id      = azurerm_subnet.machine_subnet.id
  route_table_id = azurerm_route_table.aro[0].id
}
