resource "azurerm_logic_app_workflow" "main" {
  name                = var.logic_app_name
  location            = "northcentralus"
  resource_group_name = data.azurerm_resource_group.main.name
  enabled             = false

  identity {
    type = "SystemAssigned"
  }

  parameters = {
    "$connections" = jsonencode({
      sql = {
        connectionId   = azurerm_api_connection.sql_osa_connection.id
        connectionName = "sql-osa-connection"
        id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/northcentralus/managedApis/sql"
      }
      office365 = {
        connectionId   = azurerm_api_connection.office365.id
        connectionName = "office365"
        id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/northcentralus/managedApis/office365"
      }
      teams = {
        connectionId   = azurerm_api_connection.teams.id
        connectionName = "teams"
        id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/northcentralus/managedApis/teams"
      }
    })
  }

  workflow_parameters = {
    "$connections" = jsonencode({
      defaultValue = {}
      type         = "Object"
    })
  }

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_logic_app_trigger_recurrence" "every_2_minutes" {
  name         = "Recurrence"
  logic_app_id = azurerm_logic_app_workflow.main.id
  frequency    = "Minute"
  interval     = 2
}
