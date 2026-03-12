resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = "centralus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

# Blob Containers
locals {
  blob_containers = [
    "azure-webjobs-eventhub",
    "azure-webjobs-hosts",
    "azure-webjobs-secrets",
    "funcosapoc-applease",
    "function-releases",
    "predictions",
    "scm-releases",
    "shelf-images",
  ]

  file_shares = [
    "func-osa-poc02d3d362c591",
    "func-osa-poc-temp-0018a9f20fb1fea",
  ]

  storage_queues = [
    "azure-webjobs-blobtrigger-func-osa-poc",
    "funcosapoc-control-00",
    "funcosapoc-control-01",
    "funcosapoc-control-02",
    "funcosapoc-control-03",
    "funcosapoc-workitems",
    "webjobs-blobtrigger-poison",
  ]

  storage_tables = [
    "Alerts",
    "funcosapocHistory",
    "funcosapocInstances",
    "funcosapocPartitions",
  ]
}

resource "azurerm_storage_container" "containers" {
  for_each              = toset(local.blob_containers)
  name                  = each.value
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_storage_share" "shares" {
  for_each           = toset(local.file_shares)
  name               = each.value
  storage_account_id = azurerm_storage_account.main.id
  quota              = 5120
}

resource "azurerm_storage_queue" "queues" {
  for_each             = toset(local.storage_queues)
  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}

resource "azurerm_storage_table" "tables" {
  for_each             = toset(local.storage_tables)
  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}
