resource "azurerm_service_plan" "main" {
  name                = var.service_plan_name
  location            = "canadacentral"
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_linux_function_app" "main" {
  name                       = var.function_app_name
  location                   = "canadacentral"
  resource_group_name        = data.azurerm_resource_group.main.name
  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.primary.instrumentation_key
    "EVENT_HUB_CONN"                 = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.eastus.vault_uri}secrets/EventHubConn/)"
    "AI_VISION_KEY"                  = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.eastus.vault_uri}secrets/AiVisionKey/)"
    "CUSTOM_VISION_KEY"              = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.eastus.vault_uri}secrets/CustomVisionKey/)"
    "SQL_SERVER"                     = azurerm_mssql_server.main.fully_qualified_domain_name
    "SQL_DATABASE"                   = var.sql_database_name
    "SQL_PASSWORD"                   = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.eastus.vault_uri}secrets/SqlPassword/)"
    "STORAGE_ACCOUNT_NAME"           = azurerm_storage_account.main.name
    "STORAGE_ACCOUNT_KEY"            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.eastus.vault_uri}secrets/StorageAccountKey/)"
  }

  tags = {
    environment = "poc"
    project     = "osa"
  }
}
