locals {
  name         = "eks-bp-demo"
  cluster_name = "eks-bp-demo"
}
#endregion

#region EKS BLUEPRINTS
module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.8.0"

  # EKS CLUSTER
  cluster_name       = local.cluster_name
  cluster_version    = "1.22"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  # EKS MANAGED NODE GROUPS
  managed_node_groups = {
    mg_m5 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["m5.large"]
      min_size        = 2
      max_size        = 4
      subnet_ids      = module.vpc.private_subnets
    }
  }

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.8.0"

  eks_cluster_id = module.eks_blueprints.eks_cluster_id

  #region EKS ADDONS
  enable_amazon_eks_vpc_cni = true
  enable_amazon_eks_coredns = true
  amazon_eks_coredns_config = {
    most_recent        = true
    kubernetes_version = "1.22"
    resolve_conflicts  = "OVERWRITE"
  }
  enable_amazon_eks_kube_proxy         = true
  enable_amazon_eks_aws_ebs_csi_driver = true
  #endregion

  #region K8s ADDONS
  enable_argocd = true

  argocd_helm_config = {
    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = bcrypt(data.aws_secretsmanager_secret_version.admin_password_version.secret_string)
      }
    ]
  }

  argocd_manage_add_ons = true # Indicates that ArgoCD is responsible for managing/deploying add-ons
  argocd_applications = {
    addons = {
      path               = "chart"
      repo_url           = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
      add_on_application = true
    }
    workloads-dev = {
      path               = "argocd-apps/dev"
      repo_url           = "https://github.com/lkravi/eks_blueprints_workloads"
      add_on_application = false
    }
  }


 enable_aws_load_balancer_controller = true
  
  }

  enable_aws_for_fluentbit            = false
  enable_cluster_autoscaler           = true
  enable_metrics_server               = true
  enable_prometheus                   = false
  enable_grafana                      = false
  enable_external_secrets             = false
  enable_aws_efs_csi_driver           = false
  enable_aws_cloudwatch_metrics       = false
  #endregion

  depends_on = [
    time_sleep.wait_for_cluster
  ]
}
