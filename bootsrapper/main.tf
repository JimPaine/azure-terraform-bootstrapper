provider "azuread" {
  version = "~> 0.7"
}

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

resource "azuread_application" "lab" {
  name                       = "terraclient${random_id.lab.dec}"
  homepage                   = "https://homepage"
  identifier_uris            = ["https://uri${random_id.lab.dec}"]
  reply_urls                 = ["https://uri${random_id.lab.dec}"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = true
}

resource "azuread_service_principal" "lab" {
  application_id = azuread_application.lab.application_id
}

resource "random_string" "lab" {
  length  = "32"
  special = true
}

resource "azuread_service_principal_password" "lab" {
  service_principal_id = azuread_service_principal.lab.id
  value                = random_string.lab.result
  end_date             = "2020-01-01T01:02:03Z"
}

data "azurerm_client_config" "lab" {}

# Work around until the object id is output for the user
data "external" "lab" {
  program = ["az","ad","signed-in-user","show", "-o=json","--query","{displayName: displayName,objectId: objectId,objectType: objectType}"]
}

resource "azurerm_role_assignment" "lab" {
  scope                = "/subscriptions/${data.azurerm_client_config.lab.subscription_id}"
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.lab.id
}

resource "azurerm_key_vault" "lab" {
  name                = "vault${random_id.lab.dec}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tenant_id           = data.azurerm_client_config.lab.tenant_id

  sku {
    name = "standard"
  }

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

resource "azurerm_key_vault_secret" "client-id" {
    name = "clientid"
    value = azuread_application.lab.application_id
    vault_uri = azurerm_key_vault.lab.vault_uri
}

resource "azurerm_key_vault_secret" "client-secret" {
    name = "clientsecret"
    value = random_string.lab.result
    vault_uri = azurerm_key_vault.lab.vault_uri
}

resource "azurerm_key_vault_secret" "subscription-id" {
    name = "subscriptionid"
    value = data.azurerm_client_config.lab.subscription_id
    vault_uri = azurerm_key_vault.lab.vault_uri
}

resource "azurerm_key_vault_secret" "tenant-id" {
    name = "tenantid"
    value = data.azurerm_client_config.lab.tenant_id
    vault_uri = azurerm_key_vault.lab.vault_uri
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
  resource_group_name   = azurerm_resource_group.lab.name
  storage_account_name  = azurerm_storage_account.lab.name
  container_access_type = "private"
}

resource "azurerm_key_vault_secret" "storage-account" {
    name = "storageaccount"
    value = azurerm_storage_account.lab.name
    vault_uri = azurerm_key_vault.lab.vault_uri
}

resource "azurerm_key_vault_secret" "container-name" {
    name = "containername"
    value = azurerm_storage_container.lab.name
    vault_uri = azurerm_key_vault.lab.vault_uri
}

resource "azurerm_key_vault_secret" "access-key" {
    name = "accesskey"
    value = azurerm_storage_account.lab.primary_access_key
    vault_uri = azurerm_key_vault.lab.vault_uri
}


resource "azurerm_key_vault_secret" "resource-group" {
    name = "resourcegroup"
    value = azurerm_resource_group.lab.name
    vault_uri = azurerm_key_vault.lab.vault_uri
}