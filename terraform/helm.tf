provider "helm" {
    service_account = "tiller"
    #tiller_image    = "gcr.io/kubernetes-helm/tiller:v2.14.1"
}

#Add the OpenFaaS helm repository: 
data "helm_repository" "openfaas" {
    name = "openfaas"
    url  = "https://openfaas.github.io/faas-netes/"
}

resource "helm_release" "openfaas" {
    depends_on = [
        "kubernetes_cluster_role_binding.tiller",
    ]

    chart      = "openfaas"
    name       = "openfaas"
    namespace  = "${kubernetes_namespace.openfaas.metadata.0.name}"
    repository = "${data.helm_repository.openfaas.metadata.0.name}"

    set {
        name  = "basic_auth"
        value = "true"
    }

    set {
        name = "functionNamespace"
        value = "openfaas-fn"
    }

}

