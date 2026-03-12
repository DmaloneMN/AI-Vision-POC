resource "azurerm_api_connection" "office365" {
  name                = "office365"
  resource_group_name = data.azurerm_resource_group.main.name
  managed_api_id      = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/northcentralus/managedApis/office365"

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_api_connection" "sql" {
  name                = "sql"
  resource_group_name = data.azurerm_resource_group.main.name
  managed_api_id      = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/northcentralus/managedApis/sql"

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_api_connection" "sql_osa_connection" {
  name                = "sql-osa-connection"
  resource_group_name = data.azurerm_resource_group.main.name
  managed_api_id      = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/northcentralus/managedApis/sql"

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_api_connection" "teams" {
  name                = "teams"
  resource_group_name = data.azurerm_resource_group.main.name
  managed_api_id      = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/northcentralus/managedApis/teams"

  tags = {
    environment = "poc"
    project     = "osa"
  }
}
