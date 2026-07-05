variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
  default     = "rg-infra-lab"
}
variable "resource_group_name_2" {
  description = "Nombre del Resource Group"
  type        = string
  default     = "rg-Guest-lab"
}
variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "spaincentral"
}

variable "vnet_name" {
  description = "Nombre de la VNet"
  type        = string
  default     = "vnet-infra-lab"
}


variable "vm_size" {
  description = "Tamaño de la VM"
  type        = string
  default     = "Standard_B2ls_v2"
}

variable "admin_username" {
  description = "Usuario administrador de la VM"
  type        = string
  default     = "administrador"
}

variable "admin_password" {
  description = "Contraseña administrador"
  type        = string
  sensitive   = true
}