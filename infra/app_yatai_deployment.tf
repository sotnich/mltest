# see https://docs.bentoml.org/projects/yatai/en/latest/installation/yatai_deployment.html

resource "kubernetes_namespace" "yatai-deployment" {
    metadata {
        name = "yatai-deployment"
    }
}

resource "helm_release" "yatai-deployment-crds" {
    name      = "yatai-deployment-crds"
    namespace = "yatai-deployment"

    repository = "https://bentoml.github.io/helm-charts"
    chart      = "yatai-deployment-crds"

    depends_on = [helm_release.cert-manager, module.eks]
}

resource "helm_release" "yatai-deployment" {
    name      = "yatai-deployment"
    namespace = "yatai-deployment"

    repository = "https://bentoml.github.io/helm-charts"
    chart      = "yatai-deployment"

    set {
        name  = "layers.network.ingressClass"
        value = "nginx"
    }

    depends_on = [helm_release.yatai-deployment-crds, helm_release.yatai-image-builder, module.eks]
}
