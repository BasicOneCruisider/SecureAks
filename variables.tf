# Nom du projet et de l'environnement (pour un nommage cohérent)
variable "project_prefix" {
  description = "Préfixe du projet pour toutes les ressources (ex: prod-zt)."
  type        = string
  default     = "prod-zt"
}

variable "environment" {
  description = "L'environnement de déploiement (prod, staging, dev)."
  type        = string
  default     = "prod"
}

# Configuration Régionale
variable "location" {
  description = "La région Azure pour le déploiement. Doit être en minuscules et sans espace (ex: westeurope)."
  type        = string
  default     = "westeurope"
}

# Configuration du Réseau
variable "vnet_address_space" {
  description = "Le CIDR du VNet principal."
  type        = string
  default     = "10.100.0.0/16"
}

variable "aks_subnet_address_prefix" {
  description = "Le CIDR du sous-réseau AKS. (Assurez-vous qu'il y a suffisamment d'adresses pour les pods Azure CNI)."
  type        = string
  default     = "10.100.1.0/24"
}

# Configuration AKS
variable "kubernetes_version" {
  description = "Version de Kubernetes à utiliser (ex: 1.29)."
  type        = string
  default     = "1.29" 
}

# Paramètres du Node Pool Système
variable "system_node_count" {
  description = "Nombre initial de nœuds pour le pool système."
  type        = number
  default     = 2
}

variable "system_vm_size" {
  description = "Taille de la VM pour les nœuds du pool système (ex: Standard_DS2_v2)."
  type        = string
  default     = "Standard_DS2_v2" 
}

# Configuration de Sécurité et Identité (Entra ID)
variable "aks_admin_group_object_ids" {
  description = "Liste des Object IDs des groupes Entra ID (Azure AD) ayant le rôle Cluster Admin (RBAC). **CRUCIAL pour le Zero Trust.**"
  type        = list(string)
  # Remplacer par un VRAI GUID de groupe de sécurité Entra ID
  default     = ["1a2b3c4d-5e6f-7a8b-9c0d-e1f2a3b4c5d6"] 
}