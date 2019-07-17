provider "helm" {
  debug = true
  install_tiller  = true
  service_account = "tiller"
  namespace = "kube-system"
  #service_account = "${kubernetes_service_account.tiller.metadata.0.name}"
  #namespace       = "${kubernetes_service_account.tiller.metadata.0.namespace}"
  tiller_image    = "gcr.io/kubernetes-helm/tiller:v2.14.1"

  kubernetes {
    config_path = "~/.kube/config"
  }
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

    # Set: Value block with custom values to be merged with the values yaml.
    set {
        name  = "basic_auth"
        value = "true"
    }

    set {
        name = "functionNamespace"
        value = "openfaas-fn"
    }

}

