resource "kubernetes_pod" "grafana" {
  metadata {
    name = "grafana"
    labels = {
      App = "grafana"
    }
    namespace = "openfaas"
  }
  spec {
    container {
      image = "stefanprodan/faas-grafana:4.6.3"
      name = "grafana"

      port {
        container_port = 3000
      }
    }
  }
}

resource "kubernetes_service" "grafana" {
  metadata {
    name = "grafana"
    namespace = "openfaas"
  }
  spec {
    selector {
      App = "${kubernetes_pod.grafana.metadata.0.labels.App}"
    }
    port {
      port = 3000
      target_port = 3000
    }
    type = "NodePort"
  }
}
