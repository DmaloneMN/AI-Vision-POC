resource "azurerm_eventhub_namespace" "main" {
  name                = var.eventhub_namespace_name
  location            = "canadacentral"
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"
  capacity            = 1
  zone_redundant      = true
  kafka_enabled       = true

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_eventhub_namespace_authorization_rule" "func_app_policy" {
  name                = "func-app-policy"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = data.azurerm_resource_group.main.name

  listen = true
  send   = true
  manage = false
}

resource "azurerm_eventhub" "main" {
  name                = var.eventhub_name
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_consumer_group" "default" {
  name                = "$Default"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.main.name
  resource_group_name = data.azurerm_resource_group.main.name
}
