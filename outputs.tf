output "resource_group_name" {
  description = "Nom du groupe de ressources."
  value       = azurerm_resource_group.rg_aks.name
}

output "aks_cluster_name" {
  description = "Nom complet du cluster AKS."
  value       = azurerm_kubernetes_cluster.aks_cluster.name
}

output "aks_principal_id" {
  description = "ID du Principal de l'identité managée du cluster (utile pour les permissions Key Vault)."
  value       = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
}

output "kube_config_command" {
  description = "Commande CLI pour se connecter au cluster (nécessite d'être sur un réseau connecté au VNet)."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg_aks.name} --name ${azurerm_kubernetes_cluster.aks_cluster.name} --overwrite-existing"
}