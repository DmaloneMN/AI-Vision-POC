data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_cognitive_account" "ai_vision" {
  name                = var.cognitive_account_name
  location            = "eastus"
  resource_group_name = data.azurerm_resource_group.main.name
  kind                = "CognitiveServices"
  sku_name            = "S0"

  tags = {
    environment = "poc"
    project     = "osa"
  }
}
