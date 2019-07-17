#!/bin/bash

export OPENFAAS_URL=$(minikube ip):31112
export PASSWORD=a418f79d1b786b3d1104033a6d2ebd243a8485d0

echo -n $PASSWORD | faas-cli login -g $OPENFAAS_URL -u admin — --password-stdin

#GRAFANA_PORT=$(kubectl -n openfaas get svc grafana -o jsonpath="{.spec.ports[0].nodePort}")

#export GRAFANA_URL=$(minikube ip):$GRAFANA_PORT/dashboard/db/openfaas
