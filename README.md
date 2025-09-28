# 🚀 Secure Azure Kubernetes Service (AKS) Cluster Deployment
![Azure Kubernetes Service](https://controlmonkey.io/wp-content/uploads/2025/09/azure-aks-terraform-guide.png)

## 🛡️ Architecture & Zero Trust Principles

This project uses Terraform to deploy a production-ready **Azure Kubernetes Service (AKS)** cluster, enforcing **Zero Trust** security principles at the Infrastructure as Code (IaC) layer.

| Security Feature | Description | Zero Trust Principle |
| :--- | :--- | :--- |
| **Private Cluster** (`private_cluster_enabled = true`) | The Kubernetes API server is isolated; access is restricted to the VNet via a private endpoint. | **Never Trust, Always Verify Access.** |
| **Entra ID (Azure AD) RBAC** | All cluster access is managed by **Azure Entra ID**. Local cluster accounts are permanently disabled (`local_account_disabled = true`). | **Identity-Based Verification.** |
| **Azure Policy for Kubernetes** | A **Pod Security Baseline Initiative** is assigned with a `Deny` effect. This rejects non-compliant workloads (e.g., privileged containers) at the Kubernetes Admission Controller level (Gatekeeper). | **Continuous Compliance Verification.** |
| **External State Management** | Terraform State is stored securely in Azure Storage with state locking. | **Controlled Access to Infrastructure Secrets.** |

---

## 🛠️ Prerequisites

Ensure you have the following tools installed and configured:

1.  **Azure CLI** (Authenticated via `az login`).
2.  **Terraform** (Version `>= 1.0.0`).
3.  **Azure Permissions** to create all required resources, including the AKS and the backend storage.
4.  **Entra ID Group ObjectID** to be configured as the Cluster Admin (must be set in `variables.tf`).

---

## 🔑 Identity and Credential Management

### 1. Terraform Deployment Credentials

For executing Terraform, authentication to Azure is required.

| Method | Use Case | Setup |
| :--- | :--- | :--- |
| **User Identity** | Local Development/Testing | Run `az login` (Terraform uses your active CLI session credentials). |
| **Service Principal (Recommended)** | CI/CD Pipelines (e.g., GitHub Actions, Azure DevOps) | Use environment variables (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, etc.). |

The identity must have **Contributor** access to the Resource Group and appropriate **Storage Blob Data Contributor** access to the Terraform State Storage Account.

### 2. AKS Cluster Access (Control Plane)

Access to the Kubernetes control plane via `kubectl` is **exclusively** managed by Entra ID RBAC.

| K8s Access | Azure Role Mapping | Control Mechanism |
| :--- | :--- | :--- |
| `cluster-admin` | Handled by Entra ID Group | Configured via `aks_admin_group_object_ids` variable. Only members of this group can manage the cluster. |

**Connection Process:**

1.  Run the `az aks get-credentials` command (see outputs).
2.  Azure CLI initiates an Entra ID browser authentication flow.
3.  Upon successful login, `kubectl` uses the user's **Entra ID Identity** for all API authorization checks.

---

## ⚙️ Configuration & Deployment Guide

### 1. Configure State Backend

Modify the values in `backend.tf` to point to your secure Azure Storage Account.

```terraform
# backend.tf must be configured with your Storage Account details
terraform {
  backend "azurerm" {
    # ⚠️ REPLACE THESE VALUES
    resource_group_name  = "rg-tfstate-prod"
    storage_account_name = "tftestatestore001" 
    container_name       = "tfstatefiles"       
    key                  = "aks/prod-zt-aks.tfstate" 
  }
}
