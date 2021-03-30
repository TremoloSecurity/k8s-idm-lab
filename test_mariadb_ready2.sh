#!/bin/bash


until /usr/bin/mysql -u root -h $(/usr/bin/kubectl get svc -n mariadb -o json | /usr/bin/jq -r .items[0].spec.clusterIP) --password=start123 -e "SELECT 1;";
do
    echo "Not Ready"
    sleep 10
done;

echo "MariaDB is running"
