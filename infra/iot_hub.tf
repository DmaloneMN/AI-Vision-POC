resource "azurerm_iothub" "main" {
  name                = var.iot_hub_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = "eastus"

  sku {
    name     = "F1"
    capacity = 1
  }

  min_tls_version = "1.2"

  tags = {
    environment = "poc"
    project     = "osa"
  }
}
