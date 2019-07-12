# Configure the OpenFaaS Provider
provider "openfaas" {
  #uri       = "http://192.168.99.103:31112"
  uri       = "${data.external.openfaas.result.openfaas_url}"
  user_name = "admin"
  password  = "${var.openfaas_password}"
}

resource "openfaas_function" "function_hello" {
  name            = "hello"
  image           = "christi3k/hello:0.0.2"
  depends_on = [
      "helm_release.openfaas"
  ]
  lifecycle = {
    create_before_destroy = true
  }
  labels = {
    depends_on = "${helm_release.openfaas.name}"
    faas_function = "hello"
  }

  annotations {
    #CreatedDate = "Fri Jul 12 07:15:55 PDT 2019"
    prometheus.io.scrape = "false"
  }
}

resource "openfaas_function" "function_primes" {
  name            = "primes"
  image           = "christi3k/primes:0.0.1"
  depends_on = [
      "helm_release.openfaas"
  ]

  labels = {
    depends_on = "${helm_release.openfaas.name}"
    faas_function = "primes"
  }

  annotations {
    #CreatedDate = "Fri Jul 12 07:15:55 PDT 2019"
    prometheus.io.scrape = "false"
  }
}

