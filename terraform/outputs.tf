#output "port" {
  #value = "${data.kubernetes_service.openfaas.spec.0.port.nodeport}"
    #depends_on = [
        #"helm_release.openfaas"
    #]
#}

output "openfaas-metadata" {
  value = "${data.kubernetes_service.openfaas.metadata}"
    #depends_on = [
        #"helm_release.openfaas"
    #]
}

output "openfaas-spec" {
  value = "${data.kubernetes_service.openfaas.spec}"
    #depends_on = [
        #"helm_release.openfaas"
    #]
}

output "openfaas_url" {
  value = "${data.external.openfaas.result["openfaas_url"]}"
  #depends_on = [
      #"helm_release.openfaas"
  #]
}


output "clusterip" {
  value = "${data.kubernetes_service.openfaas.spec.0.cluster_ip}"
    depends_on = [
        "helm_release.openfaas"
    ]
}

#Outputs:

#clusterip = 10.103.153.246
#openfaas-metadata = [
    #{
        #annotations = map[],
        #generation = 0,
        #labels = map[app:openfaas chart:openfaas-4.4.0 component:gateway heritage:Tiller release:openfaas],
        #name = gateway-external,
        #namespace = openfaas,
        #resource_version = 1195,
        #self_link = /api/v1/namespaces/openfaas/services/gateway-external,
        #uid = 8de24815-8c74-4ad1-bbbf-9f859b014aed
    #}
#]
#openfaas-spec = [
    #{
        #cluster_ip = 10.103.153.246,
        #external_ips = [],
        #external_name = ,
        #external_traffic_policy = Cluster,
        #load_balancer_ip = ,
        #load_balancer_source_ranges = [],
        #port = [map[name: node_port:31112 port:8080 protocol:TCP target_port:8080]],
        #publish_not_ready_addresses = 0,
        #selector = map[app:gateway],
        #session_affinity = None,
        #type = NodePort
    #}
#]
