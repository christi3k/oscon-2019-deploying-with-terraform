## Deploying Functions

export OPENFAAS_URL=$(minikube ip):31112

echo -n $PASSWORD | faas-cli login -g $OPENFAAS_URL -u admin — --password-stdin

### From faas-cli

https://docs.openfaas.com/tutorials/first-python-function/

faas-cli new --lang python3 hello

faas-cli build -f ./hello.yml
faas-cli push -f ./hello.yml
faas-cli deploy -f ./hello.yml

`deploy` creates a new k8s deployment in which our function runs.

### From Terraform

https://github.com/ewilde/terraform-provider-openfaas

Configure OpenFaaS provider:

```
provider "openfaas" {
  uri       = "http://192.168.99.106:31112"
  #uri       = "${data.external.openfaas.result.openfaas_url}"
  user_name = "admin"
  password  = "${var.openfaas_password}"
}
```

Define `hello` function:

```
resource "openfaas_function" "function_hello" {
  name            = "hello"
  image           = "christi3k/hello:0.0.2"
  depends_on = [
      "helm_release.openfaas"
  ]
  labels = {
    faas_function = "hello"
    canary = "false"
  }
```

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
  ignore_changes = ["labels.favorite", "labels.favorite"]
}
```


