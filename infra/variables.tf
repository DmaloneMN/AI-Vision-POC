variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = "32cac44c-6e25-4b5c-8bb7-d8782197489b"
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  default     = "b1b5c504-6f69-4e15-9c40-ddea95f2b70b"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-osa-poc"
}

variable "iot_hub_connection_string" {
  description = "IoT Hub connection string"
  type        = string
  sensitive   = true
}

variable "iot_hub_container_name" {
  description = "IoT Hub container name"
  type        = string
  sensitive   = true
}

variable "vulnerability_assessment_storage_container_path" {
  description = "Storage container path for SQL vulnerability assessments"
  type        = string
  sensitive   = true
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "sql_admin_login" {
  description = "SQL Server administrator login"
  type        = string
  default     = "sqladmin"
}

variable "cognitive_account_name" {
  description = "Name of the Cognitive Services account"
  type        = string
  default     = "ai-vision-osa-poc"
}

variable "iot_hub_name" {
  description = "Name of the IoT Hub"
  type        = string
  default     = "iot-osa-poc"
}

variable "eventhub_namespace_name" {
  description = "Name of the Event Hub namespace"
  type        = string
  default     = "osa-poc-ev"
}

variable "eventhub_name" {
  description = "Name of the Event Hub"
  type        = string
  default     = "event-hub-osa"
}

variable "storage_account_name" {
  description = "Name of the Storage Account"
  type        = string
  default     = "rgosapocbb40"
}

variable "sql_server_name" {
  description = "Name of the SQL Server"
  type        = string
  default     = "sql-osa-poc"
}

variable "sql_database_name" {
  description = "Name of the SQL Database"
  type        = string
  default     = "db-osa-poc"
}

variable "function_app_name" {
  description = "Name of the Function App"
  type        = string
  default     = "func-osa-poc"
}

variable "service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "asp-osa-poc"
}

variable "logic_app_name" {
  description = "Name of the Logic App"
  type        = string
  default     = "la-osa-poc"
}

variable "managed_identity_name" {
  description = "Name of the User Assigned Managed Identity"
  type        = string
  default     = "mi-osa-poc"
}

variable "key_vault_name_canadacentral" {
  description = "Name of the Key Vault in canadacentral"
  type        = string
  default     = "kv-osa-poc"
}

variable "key_vault_name_eastus" {
  description = "Name of the Key Vault in eastus"
  type        = string
  default     = "kv-osa-poc-11189"
}

variable "app_insights_name" {
  description = "Name of the primary Application Insights resource"
  type        = string
  default     = "func-osa-poc"
}

variable "app_insights_name_secondary" {
  description = "Name of the secondary Application Insights resource"
  type        = string
  default     = "func-osa-poc202603021855"
}

variable "sql_ad_admin_login" {
  description = "Azure AD admin login for SQL Server"
  type        = string
  default     = "sqladmin-aad"
}

variable "sql_ad_admin_object_id" {
  description = "Azure AD admin object ID for SQL Server"
  type        = string
  default     = ""
}

variable "client_ip_address" {
  description = "Client IP address for SQL firewall rule"
  type        = string
  default     = "73.62.223.21"
}
