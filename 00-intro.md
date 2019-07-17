## Deploying containerized and serverless apps with Terraform

* OSCON 2019
* Portland, OR
* 18 July 2019

Notes and code: 
* https://github.com/christi3k/oscon-2019-deploying-with-terraform
* https://auth.fyi/oscon-2019

## Who am I?

* Christie Koehler
* @christi3k

Recently a Developer Advocate at HashiCorp, now looking for my next gig!

## In this session...

* Live-deploy containerized and serverless apps with Terraform.
* Working locally with [Minikube](https://github.com/kubernetes/minikube) and
  [OpenFaaS](https://www.openfaas.com).

All of the Terraform features I'll demonstrate applies just as well to the
different cloud providers and their managed services.

**Note:** I'm using Terraform v0.11.14 for this talk. As of this commit, the
latest version of Terraform is 0.12.4 and there have been significant changes.

## Prerequites

On my laptop, I've installed and configured the following:

- [Minikube](https://github.com/kubernetes/minikube)
- [faas-cli](https://github.com/openfaas/faas-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [terraform](https://www.terraform.io/downloads.html) version 0.11.14
- [openfaas provider](https://github.com/ewilde/terraform-provider-openfaas)
  for Terraform (thank you Edward Wilde!!)

...and probably other things I don't remember
