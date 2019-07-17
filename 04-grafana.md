# Auto-scaling and metrics

OpenFaaS includes [auto-scaling]](https://docs.openfaas.com/architecture/autoscaling/).

The default rule is for "AlertManager reads usage (requests per second) metrics from Prometheus in order to know when to fire an alert to the API Gateway."

"For each alert fired the auto-scaler will add a number of replicas, which is a defined percentage of the max replicas. This percentage can be set using com.openfaas.scale.factor. For example setting com.openfaas.scale.factor=100 will instantly scale to max replicas. This label enables to define the overall scaling behavior of the function."

## Generating load

I've included a very simple script for generating load to our primes function using the `faas-cli invoke` command.

`load-test.sh` looks like:

```
for i in {0..5000};
do
   echo -n "$RANDOM" | faas-cli invoke primes && echo;
done;
```

Let's start that and let it run while we install Grafana...

## Install Grafana

[Grafana](https://grafana.com) is an open source product for creating visual dashboards for analytics. It integrates with Prometheus and many other data sources.

We're going to install it using an image custom-built for use with OpenFaas. 

Here's the terraform, in `grafana.tf`:

```
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
```

Once we `terraform apply` we can then open the dashboard with `minikube service grafana`. The default username and password is admin/admin.

Links:

Metrics - OpenFaaS
https://docs.openfaas.com/architecture/metrics/#monitoring-functions

