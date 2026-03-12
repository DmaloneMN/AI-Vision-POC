resource "azurerm_mssql_server" "main" {
  name                         = var.sql_server_name
  resource_group_name          = data.azurerm_resource_group.main.name
  location                     = "westus2"
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password

  minimum_tls_version = "1.2"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  azuread_administrator {
    login_username              = var.sql_ad_admin_login
    object_id                   = var.sql_ad_admin_object_id
    azuread_authentication_only = false
  }

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_mssql_database" "main" {
  name         = var.sql_database_name
  server_id    = azurerm_mssql_server.main.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  sku_name     = "GP_S_Gen5_2"
  max_size_gb  = 32

  auto_pause_delay_in_minutes = 60

  storage_account_type = "Local"

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services_alt" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "client_ip" {
  name             = "ClientIP"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = var.client_ip_address
  end_ip_address   = var.client_ip_address
}

resource "azurerm_mssql_firewall_rule" "query_editor" {
  name             = "QueryEditor"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "24.206.84.228"
  end_ip_address   = "24.206.84.228"
}

resource "azurerm_mssql_server_security_alert_policy" "main" {
  resource_group_name = data.azurerm_resource_group.main.name
  server_name         = azurerm_mssql_server.main.name
  state               = "Enabled"
}

resource "azurerm_mssql_server_vulnerability_assessment" "main" {
  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.main.id
  storage_container_path          = var.vulnerability_assessment_storage_container_path

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
  }
}
