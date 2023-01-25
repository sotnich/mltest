module "eks" {
    source          = "terraform-aws-modules/eks/aws"
    version         = "19.0.4"
    cluster_name    = var.project_name
    cluster_version = "1.24"

    cluster_enabled_log_types = []

    subnet_ids                     = data.aws_subnets.default_subnets.ids
    vpc_id                         = data.aws_vpc.default_vpc.id
    cluster_endpoint_public_access = true

    eks_managed_node_group_defaults = {
        ami_type = "AL2_x86_64"
    }

    cluster_addons = {}

    eks_managed_node_groups = {
        one = {
            name = "node-group"

#            instance_types = ["t2.micro"]
            instance_types = ["t3.medium"]

            min_size     = 1
            max_size     = 6
            desired_size = 2
        }
    }
}

resource "helm_release" "ingress-nginx" {
    name             = "ingress-nginx"
    namespace        = "ingress-nginx"
    create_namespace = true

    repository = "https://kubernetes.github.io/ingress-nginx"
    chart      = "ingress-nginx"

    depends_on = [module.eks]
}

resource "helm_release" "cert-manager" {
    name             = "cert-manager"
    version          = "v1.11.0"
    namespace        = "cert-manager"
    create_namespace = true

    repository = "https://charts.jetstack.io"
    chart      = "cert-manager"

    set {
        name  = "installCRDs"
        value = "true"
    }

    depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks_auth" {
    name = var.project_name
}

provider "kubernetes" {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks_auth.token
}

provider "helm" {
    kubernetes {
        host                   = module.eks.cluster_endpoint
        cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
        token                  = data.aws_eks_cluster_auth.eks_auth.token
    }
}