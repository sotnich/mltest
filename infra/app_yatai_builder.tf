# see https://docs.bentoml.org/projects/yatai/en/latest/installation/yatai_image_builder.html

resource "kubernetes_namespace" "yatai-image-builder" {
    metadata {
        name = "yatai-image-builder"
    }
}

resource "kubernetes_namespace" "yatai" {
    metadata {
        name = "yatai"
    }
}

resource "aws_ecr_repository" "repo" {
    name         = "yatai-bentos"
    force_delete = true
}

resource "aws_iam_role" "for_yatai_image_build_service_account" {
    name               = "${var.project_name}-for-yatai-image-build-service-account"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${module.eks.oidc_provider_arn}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud": "sts.amazonaws.com",
                    "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:yatai:yatai-image-builder-pod"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_image_build_full_ecr" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
    role       = aws_iam_role.for_yatai_image_build_service_account.name
}

resource "kubernetes_service_account" "yatai-image-builder-pod" {
    metadata {
        name        = "yatai-image-builder-pod"
        namespace   = "yatai"
        annotations = {
            "eks.amazonaws.com/role-arn" : aws_iam_role.for_yatai_image_build_service_account.arn
        }
        labels = {
            "yatai.ai/yatai-image-builder-pod" = "true"
        }
    }
}



resource "helm_release" "yatai-image-builder-crds" {
    name      = "yatai-image-builder-crds"
    namespace = "yatai-image-builder"

    repository = "https://bentoml.github.io/helm-charts"
    chart      = "yatai-image-builder-crds"

    depends_on = [helm_release.cert-manager, module.eks]
}

resource "helm_release" "yatai-image-builder" {
    name      = "yatai-image-builder"
    namespace = "yatai-image-builder"

    repository = "https://bentoml.github.io/helm-charts"
    chart      = "yatai-image-builder"

    set {
        name = "dockerRegistry.useAWSECRWithIAMRole"
        value = "true"
    }

    set {
        name = "dockerRegistry.awsECRRegion"
        value = var.aws_region
    }

    set {
        name = "dockerRegistry.bentoRepositoryName"
        value = aws_ecr_repository.repo.name
    }

    set {
        name = "dockerRegistry.secure"
        value = "false"
    }

    set {
        name = "dockerRegistry.password"
        value = ""
    }

    set {
        name = "dockerRegistry.username"
        value = ""
    }

    set {
        name = "dockerRegistry.inClusterServer"
        value = split("/", aws_ecr_repository.repo.repository_url)[0]
    }

    set {
        name = "dockerRegistry.server"
        value = split("/", aws_ecr_repository.repo.repository_url)[0]
    }

    depends_on = [
        module.eks,
        helm_release.yatai,
        aws_iam_role.for_yatai_image_build_service_account,
        kubernetes_namespace.yatai-image-builder,
        helm_release.yatai-image-builder-crds,
        aws_ecr_repository.repo
    ]
}
