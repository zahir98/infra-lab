output "public_ip" {
  description = "IP pública de SRV-DC-S01"
  value       = azurerm_public_ip.dc01_pip.ip_address
}

output "private_ip" {
  description = "IP privada de SRV-DC-S01"
  value       = azurerm_network_interface.dc01_nic.private_ip_address
}

output "resource_group" {
  description = "Nombre del Resource Group"
  value       = azurerm_resource_group.rg.name
}