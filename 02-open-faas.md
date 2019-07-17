## Installing OpenFaas

[OpenFaaS](https://www.openfaas.com) is an open source project that enables you to run serverless functions anywhere via Docker Swarm or Kubernetes. For this talk, we'll deploy OpenFaaS on a Kubernetes cluster running on my laptop (via minikube).

First we need to install OpenFaas. We're going to do this using Terraform.  While we're doing that, we'll compare with how we would do the same steps via configuration files or the command line.

No changes quite yet to Terraform providers since we'll be using Kubernetes until OpenFaas is set up.

### Tiller and Helm

We're going to use a [Helm](https://github.com/openfaas/faas-netes/blob/master/chart/openfaas/README.md) chart to install OpenFaaS. We need to do some set up in order to be able to use Helm.

First, we create a Service Account for Tiller, which is the server-side component of Helm.

Command line:

```
kubectl -n kube-system create sa tiller
```

Terraform (in `k8s.tf`):

```
resource "kubernetes_service_account" "tiller" {
    metadata {
        name      = "tiller"
        namespace = "kube-system"
    }

    automount_service_account_token = true
}
```

Next, we need to create a ClusterRoleBinding for Tiller, allowing that Service Account to administer the cluster:

```
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
```

Terraform (in `k8s.tf`):

```
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

```

Next, we'll need to ensure that Tiller is installed on the cluster. On the command line, you would use the following:

```
helm init --skip-refresh --upgrade --service-account tiller
```

In Terraform, to use Helm, we specify the Helm provider and Tiller will be installed automatically.

First, we'll create `helm.tf` and add the following:

```
provider "helm" {
  debug = true
  install_tiller  = true
  service_account = "tiller"
  namespace = "kube-system"
  tiller_image    = "gcr.io/kubernetes-helm/tiller:v2.14.1"

  kubernetes {
    config_path = "~/.kube/config"
  }
}
```

Where we specify the name of the service account tiller should use. Here we can also configure which version of tiller to use.

Because we've updated provider configuration, we should re-run `terraform init`.

```
terraform init

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "helm" (0.10.0)...
...
* provider.helm: version = "~> 0.10"
* provider.kubernetes: version = "~> 1.8"
```


### Install OpenFaaS helm repo

Add the OpenFaaS helm repository: 

On the command line, you would do the following:

```
helm repo add openfaas https://openfaas.github.io/faas-netes/
```

In Terraform, we'll add a `helm_repository` data source to our helm configuration (`helm.tf`):

```
data "helm_repository" "openfaas" {
    name = "openfaas"
    url  = "https://openfaas.github.io/faas-netes/"
}
```

[Data sources](https://www.terraform.io/docs/configuration/data-sources.html) in Terraform expose read-only information about your infrastructure. Sometimes these are values you set in the conf file, and othertimes they are queried via the provider's API.

On the commmand line, we need to tell helm to update its charts: `helm repo update`. This isn't necessary for Terraform because it will happen automatically upon `terraform apply`.

### Generate a password for OpenFaas & Configure secret

I've already run the following command and saved the password information in a `.env` file that's loaded automatically when I enter a directory.

If you're following along, you'd do something like the following:

```
export PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)
```

You'd need to do something like this whether or not you're using Terraform or not. You might also use a secrets management solution such as HashiCorp Vault or ?

### Create Kubernetes secret

Next, we'll create a secret to use with OpenFaaS using the password we generated.

Command line:

```
kubectl -n openfaas create secret generic basic-auth --from-literal=basic-auth-user=admin --from-literal=basic-auth-password="$PASSWORD"
```

Terraform, in `k8s.tf`:

```
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
```

### Terraform vars

Notice in the Terraform config, we're using `var.openfaas_username` and `var.openfaas_password`.

We need to configure these variables so they are available for interpolation (`"${}"`).

There are two parts to this: `variables.tf` and `terraform.tfvars`.

In `variables.tf` you define the variables that are needed without assigning any values to them:

```
variable "openfaas_username" {
    default     = "admin"
    description = "The username to use for OpenFaaS."
    type        = "string"
}

variable "openfaas_password" {
    description = "The password to use for OpenFaaS."
    type        = "string"
}
```

In `terraform.tfvars` you define values for the variables:

```
openfaas_username = "admin"
openfaas_password = ""
```

You can also use environmental variables for this and Terraform will pick up on them. See the [Terraform docs](https://www.terraform.io/docs/index.html) for more information on [input variables](https://www.terraform.io/docs/configuration/variables.html).

### Creating namespaces for OpenFaaS

Next, we need to create namespaces for OpenFaaS core components and OpenFaaS Functions:

```
kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
```

The `namespaces.yml` file looks like:

```
apiVersion: v1
kind: Namespace
metadata:
  name: openfaas
  labels:
    role: openfaas-system
    access: openfaas-system
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: openfaas-fn
  labels:
    istio-injection: enabled
    role: openfaas-fn
```

Here's the equivelent Terraform:

```
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

```
### Install OpenFaaS via Helm chart

With the commmand line:

```
helm upgrade openfaas --install openfaas/openfaas --namespace openfaas --set functionNamespace=openfaas-fn --set basic_auth=true
```

To do this with Terraform, we'll add the following to our `helm.tf` configuration:

```
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
```

We include the `depends_on` attribute to ensure that Terraform creates our tiller service account and role-binding before attempting to install this helm chart.

At this point we should be able to `terraform plan` and `terraform apply` in order to deploy OpenFaaS.
