create service account for tiller:

command line:

kubectl -n kube-system create sa tiller

terraform:

resource "kubernetes_service_account" "tiller" {
    metadata {
        name      = "tiller"
        namespace = "kube-system"
    }
}

create role binding for tiller:

command line:

kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

terraform:

TODO: figure out what each of these are

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

yaml version:

apiVersion: rbac.authorization.k8s.io/v1
# This cluster role binding allows anyone in the "manager" group to read secrets in any namespace.
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: tiller # Name is case sensitive
  apiGroup: rbac.authorization.k8s.io
  namespace: kube-system

## Install tiller

Install tiller which is Helm’s server-side component: 

command line:

helm init --skip-refresh --upgrade --service-account tiller

terraform:

The Helm provider is used to deploy software packages in Kubernetes. The provider needs to be configured with the proper credentials before it can be used.

configure helm's access to the k8s cluster in its provider stanza.

tiller is installed by default
you can specify the image to use
can also specify the account to use

provider "helm" {
    service_account = "tiller"
    tiller_image    = "gcr.io/kubernetes-helm/tiller:v2.14.1"
}

## create namespaces

Create namespaces for OpenFaaS core components and OpenFaaS Functions: 

kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml

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

terraform:

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


## install OpenFaaS helm repo:

Add the OpenFaaS helm repository: 

command line:

helm repo add openfaas https://openfaas.github.io/faas-netes/

data "helm_repository" "openfaas" {
    name = "openfaas"
    url  = "https://openfaas.github.io/faas-netes/"
}

Update all the charts for helm: 

helm repo update

terraform:

n/a

## generate and set password for openfaas

command line:

export PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)

take a note of your password with echo $PASSWORD before continuing.

kubectl -n openfaas create secret generic basic-auth --from-literal=basic-auth-user=admin --from-literal=basic-auth-password="$PASSWORD"

terraform:

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

this must go in variables.tf (or tf.vars?):

variable "openfaas_username" {
    default     = "admin"
    description = "The username to use for OpenFaaS."
    type        = "string"
}

variable "openfaas_password" {
    description = "The password to use for OpenFaaS."
    type        = "string"
}


### Install OpenFaaS using the chart: 

command line:

helm upgrade openfaas --install openfaas/openfaas --namespace openfaas --set functionNamespace=openfaas-fn --set basic_auth=true

terraform:

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

## set env var

Set the OPENFAAS_URL env-var:

export OPENFAAS_URL=$(minikube ip):31112

echo -n $PASSWORD | faas-cli login -g $OPENFAAS_URL -u admin — --password-stdin

faas-cli login -g http://$OPENFAAS_URL -u admin — password-stdin
kubectl get pods -n openfaas

Q: How to get TF to spit out the IP?

possibly the kubectl way:
kubectl get service $SERVICE --output='jsonpath="{.spec.ports[0].nodePort}"'

kubectl get service -n openfaas gateway-external --output='jsonpath="{.spec.ports[0].nodePort}"'

probably need to use a datasource:

data "kubernetes_service" "openfaas" {
  metadata {
    name = "gateway-external"
    namespace = "openfaas"
  }
}

output "nodeport" {
  value = "${data.kubernetes_service.openfaas.port.0.nodeport}"
    depends_on = [
        "helm_release.openfaas"
    ]
}

output "port" {
  value = "${data.kubernetes_service.openfaas.port.0.port}"
    depends_on = [
        "helm_release.openfaas"
    ]
}

output "clusterip" {
  value = "${data.kubernetes_service.openfaas.spec.0.cluster_ip}"
    depends_on = [
        "helm_release.openfaas"
    ]
}

resource "aws_route53_record" "example" {
  zone_id = "${data.aws_route53_zone.k8.zone_id}"
  name    = "example"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.example.load_balancer_ingress.0.hostname}"]
}

kubectl get services -n openfaas
NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
alertmanager        ClusterIP   10.107.204.92    <none>        9093/TCP         22h
basic-auth-plugin   ClusterIP   10.105.252.173   <none>        8080/TCP         22h
gateway             ClusterIP   10.105.210.147   <none>        8080/TCP         22h
gateway-external    NodePort    10.97.158.238    <none>        8080:31112/TCP   22h
nats                ClusterIP   10.108.178.130   <none>        4222/TCP         22h
prometheus          ClusterIP   10.104.251.203   <none>        9090/TCP         22h

kubectl get service -n openfaas gateway-external

1 error occurred:
	* output.nodeport: Resource 'data.kubernetes_service.openfaas' does not have attribute 'spec.0.nodeport' for variable 'data.kubernetes_service.openfaas.spec.0.nodeport'

clusterip = 10.103.153.246

data.kubernetes_service.openfaas.spec.0.port yields:

port = [
    {
        name = ,
        node_port = 31112,
        port = 8080,
        protocol = TCP,
        target_port = 8080
    }
]


