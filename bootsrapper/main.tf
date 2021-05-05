provider "azurerm" {
  version = "~> 1.41"
}

provider "random" {
  version = "~> 2.2"
}

provider "external" {
  version = "~> 1.2"
}


variable "resource_group_name" {

}

variable "resource_group_location" {

}



resource "azurerm_resource_group" "lab" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "random_id" "lab" {
  keepers = {
    resource_group = "azurerm_resource_group.lab.name"
  }

  byte_length = 2
}

data "azurerm_client_config" "lab" {}

# Work around until the object id is output for the user
data "external" "lab" {
  program = ["az","ad","signed-in-user","show", "-o=json","--query","{displayName: displayName,objectId: objectId,objectType: objectType}"]
}

resource "azurerm_key_vault" "lab" {
  name                = "vault${random_id.lab.dec}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tenant_id           = data.azurerm_client_config.lab.tenant_id

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.lab.tenant_id
    object_id = data.external.lab.result.objectId

    key_permissions = []

    secret_permissions = [
      "list",
      "set",
      "get",
      "delete"
    ]
  }
}

resource "azurerm_key_vault_secret" "client-secret" {
    name = "clientsecret"
    value = random_string.lab.result
    key_vault_id = azurerm_key_vault.lab.id
}

resource "azurerm_key_vault_secret" "subscription-id" {
    name = "subscriptionid"
    value = data.azurerm_client_config.lab.subscription_id
    key_vault_id = azurerm_key_vault.lab.id
}

resource "azurerm_key_vault_secret" "tenant-id" {
    name = "tenantid"
    value = data.azurerm_client_config.lab.tenant_id
    key_vault_id = azurerm_key_vault.lab.id
}

resource "azurerm_storage_account" "lab" {
  name                     = "terraformstate${random_id.lab.dec}"
  resource_group_name      = azurerm_resource_group.lab.name
  location                 = azurerm_resource_group.lab.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "lab" {
  name                  = "state"
  storage_account_name  = azurerm_storage_account.lab.name
  container_access_type = "private"
}

resource "azurerm_key_vault_secret" "storage-account" {
    name = "storageaccount"
    value = azurerm_storage_account.lab.name
    key_vault_id = azurerm_key_vault.lab.id
}

resource "azurerm_key_vault_secret" "container-name" {
    name = "containername"
    value = azurerm_storage_container.lab.name
    key_vault_id = azurerm_key_vault.lab.id
}

resource "azurerm_key_vault_secret" "access-key" {
    name = "accesskey"
    value = azurerm_storage_account.lab.primary_access_key
    key_vault_id = azurerm_key_vault.lab.id
}


resource "azurerm_key_vault_secret" "resource-group" {
    name = "resourcegroup"
    value = azurerm_resource_group.lab.name
    key_vault_id = azurerm_key_vault.lab.id
}