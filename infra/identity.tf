resource "azurerm_user_assigned_identity" "main" {
  name                = var.managed_identity_name
  location            = "eastus2"
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    environment = "poc"
    project     = "osa"
  }
}
