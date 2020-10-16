#!/bin/bash


while [ "$(kubectl get pods -n cert-manager | grep Running | grep '1/1' | wc -l)" -ne 3 ];
do
    echo "Not Ready"
    sleep 10
done;

echo "CertManager is running"
