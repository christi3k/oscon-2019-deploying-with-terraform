data "external" "openfaas" {
  program = ["bash", "${path.module}/get-ip.sh"]
  #query = {
    ## arbitrary map from strings to strings, passed
    ## to the external program as the data query.
    #id = "abc123"
  #}
}


