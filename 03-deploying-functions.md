## Deploying Functions to OpenFaaS

First, we're going to use the OpenFaas cli, `faas-cli` to get a sense of the OpenFaaS deployment lifecycle.

We need to set a couple of environemntal variables first. I'm using `set-vars.sh` for this, which does the following:

```
export OPENFAAS_URL=$(minikube ip):31112

echo -n $PASSWORD | faas-cli login -g $OPENFAAS_URL -u admin — --password-stdin
```

### From faas-cli

For more details about getting started with a python function, check out this [tutorial](https://docs.openfaas.com/tutorials/first-python-function/).

To scaffold a new function, use `faas-cli new`:

```
faas-cli new --lang python3 hello
```

And then you build, push, and then deploy the function:

```
faas-cli build -f ./hello.yml
faas-cli push -f ./hello.yml
faas-cli deploy -f ./hello.yml
```

Build creates a docker image for your function. Pushing your built function requires a Docker account. I _think_ there's a way to configure OpenFaaS to deploy from a local registry, but I didn't get that working in time for this talk.

Finally, `deploy` creates a new k8s deployment in which our function runs.

### From Terraform

One of the cool things about Terraform is just how many providers there are for it. In the case of OpenFaaS, I'm using a community-supported provider from Edward Wilde: [terraform-provider-openfaas](https://github.com/ewilde/terraform-provider-openfaas).

I've already downloaded and installed the provider.

Next, we configure the OpenFaaS provider:

```
provider "openfaas" {
  uri       = "http://192.168.99.106:31112"
  #uri       = "${data.external.openfaas.result.openfaas_url}"
  user_name = "admin"
  password  = "${var.openfaas_password}"
}
```

In the provider configuration, we're making use of another data source. This time it's an `external` one that we need to define.

We'll create `data.tf` with the following:

```
data "external" "openfaas" {
  program = ["bash", "${path.module}/get-ip.sh"]
}

```

And the `get-ip.sh` script includes:

```
#!/bin/bash

set -e

#eval "$(jq -r '@sh "FOO=\(.foo) BAZ=\(.baz)"')"

OPENFAAS_URL=http://$(minikube ip):31112

jq -n --arg url "$OPENFAAS_URL" '{"openfaas_url":$url}'
```

If you also want Terraform to print the OPENFAAS_URL upon `terraform apply`, create file `outputs.tf` with the following:

```
output "openfaas_url" {
  value = "${data.external.openfaas.result["openfaas_url"]}"
}

```

Now we define our `hello` function:

```
resource "openfaas_function" "function_hello" {
  name            = "hello"
  image           = "christi3k/hello:0.0.1"
  depends_on = [
      "helm_release.openfaas"
  ]
  labels = {
    faas_function = "hello"
    canary = "false"
  }
  annotations {
    prometheus.io.scrape = "false"
  }
}
```

Again, we're using `depends_on` to ensure that Terraform installs OpenFaaS before trying to deploy this function.

If we `terraform plan` now, Terraform will complain about this resource already existing. Terraform is correct!

But we can use `terraform import` to bring the resource into our Terraform state file.

```
terraform import openfaas_function.function_hello hello
```

(In order for the above import to work, we need to hardcode the `uri` value in the `openfaas` provider config.)

```
openfaas_function.function_hello: Importing from ID "hello"...
openfaas_function.function_hello: Import complete!
  Imported openfaas_function (ID: hello)
openfaas_function.function_hello: Refreshing state... (ID: hello)

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.
```

Now we can make changes to this function with Terraform.

Let's try:

- Updating image to hello:0.0.2

What happens if an operator adds a label via the command line?

Next time we do a `terraform plan`, Terraform is going to tell us it's going to make changes to labels:

```
  ~ openfaas_function.function_hello
      labels.favorite:             "true" => ""
      labels.uid:                  "418803930" => ""
```

We can use the `lifecycle` stanza to specify changes we want Terraform to ignore:

```
lifecycle = {
  ignore_changes = ["labels.uid", "labels.favorite"]
}
```

Let's try deploy another function, this time using only Terraform:

```
resource "openfaas_function" "function_primes" {
  name            = "primes"
  image           = "christi3k/primes:0.0.1"
  depends_on = [
      "helm_release.openfaas"
  ]

  labels = {
    depends_on = "${helm_release.openfaas.name}"
    faas_function = "primes"
    com.openfaas.scale.max = 10
  }

  annotations {
    prometheus.io.scrape = "false"
  }
}
```

