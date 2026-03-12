resource "azurerm_application_insights" "primary" {
  name                = var.app_insights_name
  location            = "centralus"
  resource_group_name = data.azurerm_resource_group.main.name
  application_type    = "web"

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_application_insights" "secondary" {
  name                = var.app_insights_name_secondary
  location            = "canadacentral"
  resource_group_name = data.azurerm_resource_group.main.name
  application_type    = "web"

  tags = {
    environment = "poc"
    project     = "osa"
  }
}

resource "azurerm_monitor_smart_detector_alert_rule" "failure_anomalies_primary" {
  name                = "failure-anomalies-${var.app_insights_name}"
  resource_group_name = data.azurerm_resource_group.main.name
  severity            = "Sev3"
  scope_resource_ids  = [azurerm_application_insights.primary.id]
  frequency           = "PT1M"
  detector_type       = "FailureAnomaliesDetector"

  action_group {
    ids = []
  }
}

resource "azurerm_monitor_smart_detector_alert_rule" "failure_anomalies_secondary" {
  name                = "failure-anomalies-${var.app_insights_name_secondary}"
  resource_group_name = data.azurerm_resource_group.main.name
  severity            = "Sev3"
  scope_resource_ids  = [azurerm_application_insights.secondary.id]
  frequency           = "PT1M"
  detector_type       = "FailureAnomaliesDetector"

  action_group {
    ids = []
  }
}
