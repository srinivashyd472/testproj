terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.1.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = ""
  
}
# if you need Backend
#  pre requests : resourcegroup , storage account and container
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "Kantar"
#     storage_account_name = "kantarstoragetf"
#     container_name       = "kantarcontainer"
#     key                  = "tfstatefile1"
#   }
# }

# Resourcegroup
resource "azurerm_resource_group" "rg" {
  name     = var.rgname
  location = var.location
}

#Storageaccount
resource "azurerm_storage_account" "sgaccount" {
  name                     = var.sg_account_name 
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  allow_nested_items_to_be_public = false

   tags = {
    environment = "webapp-storage"
  }
}

# WEBAPP
resource "azurerm_service_plan" "webplan" {
  name                = var.appservice_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "P1v3"
}

resource "azurerm_linux_web_app" "webapp" {
  name                = var.appservice_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.webplan.id
  
  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true

    application_stack {
      python_version = "3.9"
    }
  }

app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "true"
    "STORAGE_ACCOUNT"   = azurerm_storage_account.sgaccount.name
    "APP_ENV"           = "production"
  }

}

#Vnet
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnetaddress
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnetaddress

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}
resource "azurerm_subnet" "pvtend_subnet" {
  name                 = var.pvtend_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.endpsubnetaddress
}

#Vnetintegration
resource "azurerm_app_service_virtual_network_swift_connection" "integration" {
  app_service_id = azurerm_linux_web_app.webapp.id
  subnet_id      = azurerm_subnet.subnet.id
}

#pvt dns for blob
resource "azurerm_private_dns_zone" "blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "blob_dns_link" {
  name                  = "blobdns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# privateendpoint_storage

resource "azurerm_private_endpoint" "storage_pvtend" {
  name                = var.pvtend_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pvtend_subnet.id

  private_service_connection {
    name                           = var.pvtservice_connection_name
    private_connection_resource_id = azurerm_storage_account.sgaccount.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
resource "azurerm_private_dns_a_record" "blob_record" {
  name                = azurerm_storage_account.sgaccount.name
  zone_name           = azurerm_private_dns_zone.blob_dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_pvtend.private_service_connection[0].private_ip_address]
}

#webapp-storage-access
resource "azurerm_role_assignment" "blob_access" {
  scope                = azurerm_storage_account.sgaccount.id
  role_definition_name = "Storage Blob Data contributor"
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
}
