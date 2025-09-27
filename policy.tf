# Récupération de l'initiative de sécurité intégrée pour AKS 
# C'est la baseline de sécurité la plus pertinente pour les clusters Linux.
data "azurerm_policy_set_definition" "aks_pod_baseline_initiative" {
  display_name = "Azure Kubernetes Service cluster pod security baseline standards for Linux-based workloads"
}

# Affectation de l'initiative au cluster AKS
resource "azurerm_resource_policy_assignment" "aks_security_baseline_assignment" {
  # Convention de nommage : pa-<initiative>-<resource_type>
  name                 = "pa-aks-pod-baseline-aks"
  resource_id          = azurerm_kubernetes_cluster.aks_cluster.id
  policy_definition_id = data.azurerm_policy_set_definition.aks_pod_baseline_initiative.id
  
  description = "Affectation de l'initiative de baseline de sécurité des pods pour appliquer le Zero Trust."
  display_name = "AKS Pod Security Baseline (Deny)"

  # Configuration du paramètre 'effect' à Deny
  # Ceci est le point central de l'application Zero Trust : toute requête non-conforme sera REJETÉE.
  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })
}