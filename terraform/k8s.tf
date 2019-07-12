# not a lot of config needed since we're running locally.
provider "kubernetes" {}

data "kubernetes_service" "openfaas" {
  metadata {
    name = "gateway-external"
    namespace = "openfaas"
  }
  depends_on = [
      "helm_release.openfaas"
  ]
}


# crete a service account for tiller
resource "kubernetes_service_account" "tiller" {
    metadata {
        name      = "tiller"
        namespace = "kube-system"
    }
}

#create role binding for tiller:
resource "kubernetes_cluster_role_binding" "tiller" {
     metadata {
        name = "tiller"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind      = "ClusterRole"
        name      = "cluster-admin"
    }
    subject {
        api_group = ""
        kind      = "ServiceAccount"
        name      = "${kubernetes_service_account.tiller.metadata.0.name}"
        namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"
    }
}

#Create namespaces for OpenFaaS core components and OpenFaaS Functions:

resource "kubernetes_namespace" "openfaas" {
    metadata {
        name = "openfaas"
        labels = {
            role = "openfaas-system"
            access = "openfaas-system"
            istio-injection = "enabled"
        }
    }
}

resource "kubernetes_namespace" "openfaas-fn" {
    metadata {
        name = "openfaas-fn"
        labels = {
            role = "openfaas-fn"
            istio-injection = "enabled"
        }
    }
}

# set authentication info for openfaas
resource "kubernetes_secret" "openfaas" {
    metadata {
        name      = "basic-auth"
        namespace = "${kubernetes_namespace.openfaas.metadata.0.name}"
    }
    data = {
        basic-auth-user     = "${var.openfaas_username}"
        basic-auth-password = "${var.openfaas_password}"
    }
}


#resource "kubernetes_pod" "nginx" {
  #metadata {
    #name = "nginx-example"
    #labels = {
      #App = "nginx"
    #}
  #}

  #spec {
    #container {
      #image = "nginx:1.7.8"
      #name  = "example"

      #port {
        #container_port = 80
      #}
    #}
  #}
#}

#resource "kubernetes_service" "nginx" {
  #metadata {
    #name = "nginx-example"
  #}
  #spec {
    #selector {
      #App = "${kubernetes_pod.nginx.metadata.0.labels.App}"
    #}
    #port {
      #port = 80
      #target_port = 80
    #}

    #type = "NodePort"
  #}
#}

#output "np_ip" {
  #value = "${kubernetes_service.nginx.spec.0.nodePort}"
#}
