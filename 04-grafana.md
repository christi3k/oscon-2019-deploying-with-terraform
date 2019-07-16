kubectl -n openfaas run \
--image=stefanprodan/faas-grafana:4.6.3 \
--port=3000 \
grafana

kubectl -n openfaas expose deployment grafana \
--type=NodePort \
--name=grafana

GRAFANA_PORT=$(kubectl -n openfaas get svc grafana -o jsonpath="{.spec.ports[0].nodePort}")

export GRAFANA_URL=$(minikube ip):$GRAFANA_PORT/dashboard/db/openfaas


https://docs.openfaas.com/architecture/metrics/#monitoring-functions

Metrics - OpenFaaS
https://docs.openfaas.com/architecture/metrics/#monitoring-functions

