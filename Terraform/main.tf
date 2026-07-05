# Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
backend "azurerm" {
    resource_group_name  = "rg-infra-lab"
    storage_account_name = "tfstatesolvetec"
    container_name       = "tfstate"
    key                  = "infra-lab.terraform.tfstate"
  }

}


provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
resource "azurerm_resource_group" "rg2" {
  name     = var.resource_group_name_2
  location = var.location
}

# VNet
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.10.0.0/16"]
}



# Subnet AD
resource "azurerm_subnet" "subnet_ad" {
  name                 = "subnet-ad"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.10.0/24"]

  # Mantener igual que en Azure — evita recreación
   default_outbound_access_enabled = false
}

# Subnet Clients
resource "azurerm_subnet" "subnet_client" {
  name                 = "subnet-client"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.20.0/24"]
    # Mantener igual que en Azure — evita recreación
  default_outbound_access_enabled = true
}

# IP Pública
resource "azurerm_public_ip" "dc01_pip" {
  name                = "SRV-DC-S01-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

# NIC — nombre real de Azure
resource "azurerm_network_interface" "dc01_nic" {
  name                = "srv-dc-s01246_z1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_ad.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.10.8"
    public_ip_address_id          = azurerm_public_ip.dc01_pip.id
  }
}

# NSG
resource "azurerm_network_security_group" "dc01_nsg" {
  name                = "SRV-DC-S01-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "WinRM"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Asociar NSG a NIC
resource "azurerm_network_interface_security_group_association" "dc01" {
  network_interface_id      = azurerm_network_interface.dc01_nic.id
  network_security_group_id = azurerm_network_security_group.dc01_nsg.id
}

# VM
resource "azurerm_windows_virtual_machine" "dc01" {
  name                              = "SRV-DC-S01"
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  size                              = var.vm_size
  admin_username                    = var.admin_username
  admin_password                    = var.admin_password
  zone                              = "1"
  secure_boot_enabled               = true
  vtpm_enabled                      = true
  vm_agent_platform_updates_enabled = true  # ← añade esto

  network_interface_ids = [
    azurerm_network_interface.dc01_nic.id
  ]

  additional_capabilities {
    hibernation_enabled = false  # ← añade este bloque
    ultra_ssd_enabled   = false
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-g2"
    version   = "latest"
  }
}
resource "azurerm_virtual_machine_extension" "dc01_winrm" {
  name                 = "winrm-setup"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc01.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"winrm quickconfig -q; winrm set winrm/config/service/auth '@{Basic=true}'; winrm set winrm/config/service '@{AllowUnencrypted=true}'; New-NetFirewallRule -Name WinRM-HTTP -DisplayName 'WinRM HTTP' -Protocol TCP -LocalPort 5985 -Action Allow\""
  })
}
/*
# ─── IMPORTS ───────────────────────────────────────────
# Adoptar infraestructura existente creada manualmente.
# Ejecutar una sola vez — después Terraform gestiona todo.
# Patrón ID: /subscriptions/{sub}/resourceGroups/{rg}/providers/{tipo}/{nombre}

# IDENTIDAD Y AGRUPACIÓN
# Resource Group — contenedor de todos los recursos del lab
import {
  to = azurerm_resource_group.rg
  id = "/subscriptions/6af2326c-cf06-4a5e-82f2-6b550956defb/resourceGroups/rg-infra-lab"
}

# RED
# VNet principal — espacio 10.10.0.0/16
import {
  to = azurerm_virtual_network.vnet
  id = "/subscriptions/6af2326c-cf06-4a5e-82f2-6b550956defb/resourceGroups/rg-infra-lab/providers/Microsoft.Network/virtualNetworks/vnet-infra-lab"
}

# Subnet para Domain Controllers — 10.10.10.0/24
import {
  to = azurerm_subnet.subnet_ad
  id = "/subscriptions/6af2326c-cf06-4a5e-82f2-6b550956defb/resourceGroups/rg-infra-lab/providers/Microsoft.Network/virtualNetworks/vnet-infra-lab/subnets/subnet-ad"
}

# Subnet para equipos cliente — 10.10.20.0/24
import {
  to = azurerm_subnet.subnet_client
  id = "/subscriptions/6af2326c-cf06-4a5e-82f2-6b550956defb/resourceGroups/rg-infra-lab/providers/Microsoft.Network/virtualNetworks/vnet-infra-lab/subnets/subnet-client"
}

# SEGURIDAD
# NSG de SRV-DC-S01 — regla RDP puerto 3389
import {
  to = azurerm_network_security_group.dc01_nsg
  id = "/subscriptions/6af2326c-cf06-4a5e-82f2-6b550956defb/resourceGroups/rg-infra-lab/providers/Microsoft.Network/networkSecurityGroups/SRV-DC-S01-nsg"
}

# Asociación NIC+NSG — une la NIC de DC01 con su NSG
# ID especial: NIC_ID|NSG_ID
import {
  to = azurerm_network_interface_security_group_association.dc01
  id = "/subscriptions/6af2326c-cf06-4a5e-82f2-6b550956defb/resourceGroups/rg-infra-lab/providers/Microsoft.Network/networkInterfaces/srv-dc-s01246_z1|/subscriptions/6af2326c-cf06-4a5e-82f2-6b550956defb/resourceGroups/rg-infra-lab/providers/Microsoft.Network/networkSecurityGroups/SRV-DC-S01-nsg"
}

# CÓMPUTO — SRV-DC-S01 (Domain Controller primario)
# IP pública estática — evita buscar IP tras cada arranque
import {
  to = azurerm_public_ip.dc01_pip
  id = "/subscriptions/6af2326c-cf06-4a5e-82f2-6b550956defb/resourceGroups/rg-infra-lab/providers/Microsoft.Network/publicIPAddresses/SRV-DC-S01-ip"
}

# NIC de DC01 — conectada a subnet-ad con IP privada 10.10.10.8
import {
  to = azurerm_network_interface.dc01_nic
  id = "/subscriptions/6af2326c-cf06-4a5e-82f2-6b550956defb/resourceGroups/rg-infra-lab/providers/Microsoft.Network/networkInterfaces/srv-dc-s01246_z1"
}

# VM Windows Server 2025 — rol DC primario solvetec.lab
import {
  to = azurerm_windows_virtual_machine.dc01
  id = "/subscriptions/6af2326c-cf06-4a5e-82f2-6b550956defb/resourceGroups/rg-infra-lab/providers/Microsoft.Compute/virtualMachines/SRV-DC-S01"
}

*/