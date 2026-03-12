output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_linux_function_app.main.default_hostname
}

output "function_app_identity_principal_id" {
  description = "Principal ID of the Function App's system-assigned managed identity"
  value       = azurerm_linux_function_app.main.identity[0].principal_id
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "iot_hub_hostname" {
  description = "Hostname of the IoT Hub"
  value       = azurerm_iothub.main.hostname
}

output "eventhub_namespace_id" {
  description = "ID of the Event Hub Namespace"
  value       = azurerm_eventhub_namespace.main.id
}

output "key_vault_uri_canadacentral" {
  description = "URI of the Key Vault in canadacentral"
  value       = azurerm_key_vault.canadacentral.vault_uri
}

output "key_vault_uri_eastus" {
  description = "URI of the Key Vault in eastus"
  value       = azurerm_key_vault.eastus.vault_uri
}

output "storage_connection_string" {
  description = "Primary connection string of the Storage Account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "Instrumentation key of the primary Application Insights"
  value       = azurerm_application_insights.primary.instrumentation_key
  sensitive   = true
}

output "logic_app_id" {
  description = "ID of the Logic App Workflow"
  value       = azurerm_logic_app_workflow.main.id
}
