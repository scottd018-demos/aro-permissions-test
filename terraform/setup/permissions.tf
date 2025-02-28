resource "terraform_data" "aro_permission_wait" {
  input = {
    cluster_name = var.cluster_name
  }

  # ensure that we create all of our objects before attempting to apply policies that restrict
  # their creation
  depends_on = [
    azurerm_subnet.control_plane_subnet,
    azurerm_subnet.jumphost-subnet,
    azurerm_subnet.machine_subnet,
    azurerm_route_table.aro,
    azurerm_nat_gateway.aro,
    azurerm_subnet_route_table_association.control_plane,
    azurerm_subnet_route_table_association.machine,
    azurerm_subnet_nat_gateway_association.control_plane,
    azurerm_subnet_nat_gateway_association.machine,
    azurerm_nat_gateway_public_ip_association.aro,
    azurerm_network_security_group.aro,
    azurerm_subnet_network_security_group_association.control_plane,
    azurerm_subnet_network_security_group_association.machine
  ]
}

module "aro_permissions" {
  source = "/Users/dscott/VSCode/github/redhat/terraform-aro-permissions"

  # NOTE: terraform installation == 'api' installation_type (as opposed to 'cli')
  installation_type = var.installation_type

  # do not output the credentials to a file
  output_as_file = true

  # use custom roles with minimal permissions
  minimal_network_role = "${var.cluster_name}-network"
  minimal_aro_role     = "${var.cluster_name}-aro"

  # cluster parameters
  cluster_name           = terraform_data.aro_permission_wait.output.cluster_name
  vnet                   = azurerm_virtual_network.main.name
  vnet_resource_group    = azurerm_resource_group.main.name
  network_security_group = var.byo_nsg ? azurerm_network_security_group.aro[0].name : null

  aro_resource_group = {
    name   = azurerm_resource_group.aro.name
    create = false
  }

  # service principals
  cluster_service_principal = {
    name   = null
    create = !var.miwi
  }

  # we don't care about installer permissions here.  we are solely focused on RP and cluster identity network permissions
  installer_service_principal = {
    name   = null
    create = true
  }
  enable_managed_identities = true

  # set custom permissions
  nat_gateways = var.outbound_type == "UserDefinedRouting" ? [azurerm_nat_gateway.aro[0].name] : []
  route_tables = var.outbound_type == "UserDefinedRouting" ? [azurerm_route_table.aro[0].name] : []

  # further restrict via policy
  # TODO: uncomment this only when PR https://github.com/Azure/ARO-RP/pull/4087 is
  #       merged and released.  Currently, the subnet/write permission is still 
  #       needed as the resource provider does a CreateOrUpdate regardless of
  #       correct subnet configuration, which needs subnet/write.  Once the above
  #       PR is merged and active, we can uncomment the below.
  #
  # TODO: also ensure this gets moved below apply_vnet_policy for consistency in 
  #       ordering of code.
  #
  apply_network_policies_to_all = true
  apply_subnet_policy           = true
  managed_resource_group        = "${azurerm_resource_group.main.name}-managed"
  apply_vnet_policy             = true
  apply_route_table_policy      = true
  apply_nat_gateway_policy      = true
  apply_nsg_policy              = var.byo_nsg
  apply_dns_policy              = false
  apply_private_dns_policy      = !var.private
  apply_public_ip_policy        = var.private

  # explicitly set location, subscription id and tenant id
  location        = var.location
  subscription_id = data.azurerm_client_config.current.subscription_id
  tenant_id       = data.azurerm_client_config.current.tenant_id
}
