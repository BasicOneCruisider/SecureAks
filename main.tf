# Configuration du Provider Azure
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Provider Block (Manquant) : 
# Bien que le bloc 'terraform' définisse les providers requis, le bloc 'provider' est nécessaire 
# pour configurer ses fonctionnalités. Il est souvent laissé vide mais doit exister.
provider "azurerm" {
  features {}
}

# ----------------------------------------------------
# 1. Ressources de Base (RG, VNet)
# ----------------------------------------------------

# Convention de nommage : rg-<prefix>-<location>-<env>
resource "azurerm_resource_group" "rg_aks" {
  name     = "rg-${var.project_prefix}-${var.location}-${var.environment}"
  location = var.location
}

# Convention de nommage : vnet-<prefix>-<location>-<env>
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project_prefix}-${var.location}-${var.environment}"
  location            = azurerm_resource_group.rg_aks.location
  resource_group_name = azurerm_resource_group.rg_aks.name
  address_space       = [var.vnet_address_space]
}

# Convention de nommage : subnet-<pool_type>-<prefix>
resource "azurerm_subnet" "aks_subnet" {
  name                 = "subnet-aks-${var.project_prefix}"
  resource_group_name  = azurerm_resource_group.rg_aks.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_subnet_address_prefix]
  
  # CORRECTION 1 : Le bloc 'delegation' doit être retiré pour un Subnet destiné à un Node Pool CNI standard.
  # La 'delegation' est typiquement utilisée pour des services comme Azure Container Instances (ACI),
  # mais elle n'est pas supportée ou requise pour le Node Pool AKS lui-même.
  /*
  delegation {
    name = "aks-delegation"
    service_principal_actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
    ]
    service_principal_names = [
      "Microsoft.ContainerService/managedClusters",
    ]
  }
  */
}

# ----------------------------------------------------
# 2. Cluster AKS (Zero Trust Configuration)
# ----------------------------------------------------

# Convention de nommage : aks-<prefix>-<location>-<env>
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks-${var.project_prefix}-${var.location}-${var.environment}"
  location            = azurerm_resource_group.rg_aks.location
  resource_group_name = azurerm_resource_group.rg_aks.name
  kubernetes_version  = var.kubernetes_version

  # Sécurité Zero Trust
  private_cluster_enabled = true 
  local_account_disabled  = true 
  azure_policy_enabled    = true 
  
  # Intégration Entra ID (Azure AD) RBAC
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true 
    admin_group_object_ids = var.aks_admin_group_object_ids
  }

  # Utilisation d'une Managed Identity (Sécurité par défaut)
  identity {
    type = "SystemAssigned"
  }
  
  # Configuration du Plan de Données (Networking & Pools)
  network_profile {
    network_plugin    = "azure" 
    service_cidr      = "10.200.0.0/16"
    dns_service_ip    = "10.200.0.10"
    
    # CORRECTION 2 : La propriété 'docker_bridge_cidr' n'est plus supportée dans la version 3.x du provider
    # si network_plugin est 'azure' (CNI). Il faut l'omettre.
    # Si elle était laissée, le plan Terraform échouerait avec une erreur de validation.
  }
  
  # Pool de Nœuds Système (Obligatoire)
  default_node_pool {
    name                = "systempool"
    
    # CONVENTION PRO : Utiliser les variables pour le nombre de nœuds du pool par défaut
    node_count          = null # Nécessaire si enable_auto_scaling = true (sera géré par min/max_count)
    vm_size             = var.system_vm_size
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id
    max_pods            = 30 
    enable_auto_scaling = true
    min_count           = 2 # Utiliser var.system_min_count si défini dans variables.tf
    max_count           = 5 # Utiliser var.system_max_count si défini dans variables.tf
    os_disk_type        = "Ephemeral" 
    node_labels = {
      "pool-type" = "system"
    }
    tags = {
      "usage" = "k8s-system"
    }
  }
}