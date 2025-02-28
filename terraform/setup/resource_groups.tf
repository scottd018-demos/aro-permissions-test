resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
}

resource "azurerm_resource_group" "aro" {
  name     = "${local.name_prefix}-aro-rg"
  location = var.location
}
