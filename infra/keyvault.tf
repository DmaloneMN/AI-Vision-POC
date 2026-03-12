resource "azurerm_key_vault" "canadacentral" {
  name                = var.key_vault_name_canadacentral
  location            = "canadacentral"
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization   = true
  soft_delete_retention_days  = 90
  purge_protection_enabled    = false

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_key_vault" "eastus" {
  name                = var.key_vault_name_eastus
  location            = "eastus"
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization   = true
  soft_delete_retention_days  = 90
  purge_protection_enabled    = false

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_key_vault_secret" "ai_vision_key" {
  name         = "AiVisionKey"
  value        = "placeholder"
  key_vault_id = azurerm_key_vault.eastus.id

  lifecycle {
    ignore_changes = [value]
  }
}

resource "azurerm_key_vault_secret" "custom_vision_key" {
  name         = "CustomVisionKey"
  value        = "placeholder"
  key_vault_id = azurerm_key_vault.eastus.id

  lifecycle {
    ignore_changes = [value]
  }
}

resource "azurerm_key_vault_secret" "eventhub_conn" {
  name         = "EventHubConn"
  value        = "placeholder"
  key_vault_id = azurerm_key_vault.eastus.id

  lifecycle {
    ignore_changes = [value]
  }
}

resource "azurerm_key_vault_secret" "sql_password" {
  name         = "SqlPassword"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.eastus.id

  lifecycle {
    ignore_changes = [value]
  }
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "StorageAccountKey"
  value        = "placeholder"
  key_vault_id = azurerm_key_vault.eastus.id

  lifecycle {
    ignore_changes = [value]
  }
}
