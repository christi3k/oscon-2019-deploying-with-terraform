variable "openfaas_username" {
    default     = "admin"
    description = "The username to use for OpenFaaS."
    type        = "string"
}

variable "openfaas_password" {
    description = "The password to use for OpenFaaS."
    type        = "string"
}
