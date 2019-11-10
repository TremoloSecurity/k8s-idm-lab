#!/bin/bash

export MARIADB_READY=$(kubectl get pods -n mariadb -o json | jq .items[0].status.containerStatuses[0].ready)

until $MARIADB_READY -eq "true"
do
    echo "Not Ready"
    sleep 10
    export MARIADB_READY=$(kubectl get pods -n mariadb -o json | jq .items[0].status.containerStatuses[0].ready)
done;

echo "MariaDB is running"

