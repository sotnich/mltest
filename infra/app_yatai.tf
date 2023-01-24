# see https://docs.bentoml.org/projects/yatai/en/latest/installation/yatai.html

resource "aws_db_instance" "bentoml_postgresql" {
    identifier          = "${var.project_name}-for-bentoml"
    vpc_security_group_ids = [aws_security_group.default.id]
    engine              = "postgres"
    instance_class      = "db.t3.micro"
    username            = "yatai"
    password            = "yatai_Admin!"
    db_name             = "yatai"
    skip_final_snapshot = true
    allocated_storage   = 20
}

resource "kubernetes_namespace" "yatai-system" {
    metadata {
        name = "yatai-system"
    }
}

resource "aws_iam_role" "for_k8s_service_account" {
    name               = "${var.project_name}-for-k8s-service-account"
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
                    "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:yatai-system:yatai"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "for_k8s_service_account_s3_full" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    role       = aws_iam_role.for_k8s_service_account.name
}

resource "kubernetes_service_account" "yatai" {
    metadata {
        name        = "yatai"
        namespace   = "yatai-system"
        annotations = {
            "eks.amazonaws.com/role-arn" : aws_iam_role.for_k8s_service_account.arn
        }
    }
}

resource "helm_release" "yatai" {
    name      = "yatai"
    namespace = "yatai-system"

    repository = "https://bentoml.github.io/helm-charts"
    chart      = "yatai"

    set {
        name  = "postgresql.host"
        value = aws_db_instance.bentoml_postgresql.address
    }

    set {
        name  = "postgresql.port"
        value = aws_db_instance.bentoml_postgresql.port
    }

    set {
        name  = "postgresql.user"
        value = aws_db_instance.bentoml_postgresql.username
    }

    set {
        name  = "postgresql.database"
        value = aws_db_instance.bentoml_postgresql.db_name
    }

    set {
        name  = "postgresql.password"
        value = aws_db_instance.bentoml_postgresql.password
    }

    set {
        name  = "postgresql.sslmode"
        value = "disable"
    }

    set {
        name  = "s3.endpoint"
        value = "s3.amazonaws.com"
    }

    set {
        name  = "s3.region"
        value = var.aws_region
    }

    set {
        name  = "s3.bucketName"
        value = aws_s3_bucket.bucket.bucket
    }

    set {
        name  = "s3.secure"
        value = "true"
    }

    set {
        name  = "s3.accessKey"
        value = ""
    }

    set {
        name  = "serviceAccount.create"
        value = "false"
    }

    set {
        name  = "serviceAccount.name"
        value = "yatai"
    }

    depends_on = [module.eks]
}

#resource "kubernetes_service" "yatai-lb" {
#    metadata {
#        name      = "yatai-lb1"
#        namespace = "yatai-system"
#    }
#    spec {
#        selector = {
#            "app.kubernetes.io/instance" = "yatai-system"
#            "app.kubernetes.io/name"     = "yatai"
#        }
#        port {
#            port        = 80
#            target_port = 7777
#        }
#
#        type = "LoadBalancer"
#    }
#}

locals {
    yatai-ui = kubernetes_ingress_v1.yatai-ingress.status.0.load_balancer.0.ingress.0.hostname
}

resource "kubernetes_ingress_v1" "yatai-ingress" {
    wait_for_load_balancer = true
    metadata {
        name      = "yatai-ingress"
        namespace = "yatai-system"
    }
    spec {
        ingress_class_name = "nginx"
        rule {
            http {
                path {
                    path = "/"
                    backend {
                        service {
                            name = "yatai"
                            port {
                                number = 80
                            }
                        }
                    }
                }
            }
        }
    }
}

output "yatai-init" {
    value = <<EOF
To create the first user for YATAI run next commands in console:
aws eks --region eu-west-3 update-kubeconfig --name ${var.project_name}
YATAI_INITIALIZATION_TOKEN=$(kubectl get secret yatai-env --namespace yatai-system -o jsonpath="{.data.YATAI_INITIALIZATION_TOKEN}" | base64 --decode)
echo "Open in browser: http://${local.yatai-ui}/setup?token=$YATAI_INITIALIZATION_TOKEN"
EOF
}

output "yatai-ui" {
    value = "http://${local.yatai-ui}"
}