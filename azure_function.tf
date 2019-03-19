provider "azurerm" {
    version = "=1.21.0"
}
backend "azurerm" {
  resource_group_name   = "${TF_VAR_rg_name}"
  storage_account_name  = "${TF_VAR_storage_name}"
  container_name        = "${TF_VAR_container_name}"
  key                   = "terraform.${TF_VAR_af_name}.tfstate" // the key needs to be unique
}
resource "azurerm_resource_group" "af_resource_group" {
  name     = "${TF_VAR_af_rg}"
  location = "${TF_VAR_af_rg_location}"
}

resource "random_id" "server" {
  keepers = {
    # Generate a new id each time we switch to a new Azure Resource Group
    rg_id = "${azurerm_resource_group.af_resource_group.name}"
  }

  byte_length = 8
}

resource "azurerm_storage_account" "af_storage" {
  name                     = "${random_id.server.hex}"
  resource_group_name      = "${azurerm_resource_group.af_resource_group.name}"
  location                 = "${azurerm_resource_group.af_resource_group.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "af_plan" {
  name                = "${TF_VAR_app_service_plan}"
  location            = "${azurerm_resource_group.af_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.af_resource_group.name}"
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_application_insights" "af_app_insight" {
  name                = "${TF_VAR_af_name}-app-insights"
  location            = "${azurerm_resource_group.af_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.af_resource_group.name}"
  application_type    = "Web"
}

resource "azurerm_function_app" "af" {
  name                      = "${TF_VAR_af_name}"
  location                  = "${azurerm_resource_group.af_resource_group.location}"
  resource_group_name       = "${azurerm_resource_group.af_resource_group.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.af_plan.id}"
  storage_connection_string = "${azurerm_storage_account.af_storage.primary_connection_string}"

  app_settings {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.af_app_insight.instrumentation_key}"
  }
}