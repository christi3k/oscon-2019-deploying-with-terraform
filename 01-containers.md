## Minikube

Minikube creates a single-node local Kubernetes cluster.

😄  minikube v1.2.0 on darwin (amd64)
💡  Tip: Use 'minikube start -p <name>' to create a new cluster, or 'minikube delete' to delete this one.
🔄  Restarting existing virtualbox VM for "minikube" ...
⌛  Waiting for SSH access ...
🐳  Configuring environment for Kubernetes v1.15.0 on Docker 18.09.6
🔄  Relaunching Kubernetes v1.15.0 using kubeadm ...
⌛  Verifying: apiserver proxy etcd scheduler controller dns
🏄  Done! kubectl is now configured to use "minikube"

- Show `minikube status`
- Show `minikube dashboard`

## Let's deploy a simple container the yaml way

- Take a look at `yaml/nginx.yml`
- Deploy with `kubectl apply -f yaml/nginx.yml`
- Verify with `minikube service nginx-example`
- Delete with `kubectl delete -f yaml/nginx.yml`

## Let's deploy with Terraform

First we need to go into our workspace directory and initialize terraform.

- `cd workspace`
- `terraform init`

Terraform wants some configuration first. Let's create one:

- `touch k8s.tf`

In this file we're going to define a provider. [Terraform Providers](https://www.terraform.io/docs/providers/) are what provide access to infrastructure APIs and allow you to create, delete, and manage resources.

Terraform configuration files are written in [HCL](https://www.terraform.io/docs/configuration/syntax.html) (HashiCorp Configuration Language).

Here's what a provider block looks like:

```
provider "kubernetes" {}
```

If we needed to do more configuration, we would provide additional information in this block. Since we're running locally, we don't need anything else.

Anytime you change provider informatin, you need to run `terraform init`.

Now let's re-create our nginx-example in Terraform.

We'll use a seperate file just to keep things tidy: `touch nginx.tf`.

First, we'll define the pod:

```
resource "kubernetes_pod" "nginx" {
  metadata {
    name = "nginx-example"
    labels = {
      App = "nginx"
    }
  }

  spec {
    container {
      image = "nginx:1.16.0-alpine"
      name  = "example"

      port {
        container_port = 80
      }
    }
  }
}
```

Then we'll define the service:

```
resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-example"
  }
  spec {
    selector {
      App = "${kubernetes_pod.nginx.metadata.0.labels.App}"
    }
    port {
      port = 80
      target_port = 80
    }

    type = "NodePort"
  }
}

```

Now we plan: `terraform plan`.

Next we apply `terraform apply`.

Somthing cool is the graph command: `terraform graph | dot -Tsvg > graph.png`.

Now let's try updating the version of nginx:

```
      image = "nginx:1.17.1-alpine"
```

