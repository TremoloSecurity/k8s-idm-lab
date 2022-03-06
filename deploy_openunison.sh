#!/bin/bash

kubectl create namespace openunison-deploy
kubectl create configmap extracerts --from-file /root/ou-configmaps -n openunison-deploy
kubectl create secret generic input --from-file /root/ou-secrets -n openunison-deploy

kubectl create -f https://raw.githubusercontent.com/OpenUnison/openunison-k8s-activedirectory/master/src/main/yaml/artifact-deployment.yaml