# Introduction

This lab is to learn how to integrate identity into a Kubernetes deployment.  Slides for the lab - https://www.slideshare.net/MarcBoorshtein/k8s-identity-management.  ***NOTE*** this lab is NOT designed to be a self learning lab.  Its meant to be presented in a classroom setting.  We have open sourced the lab as a thank you to the community that has helped us along the way while building out our projects and this training.  We hope that by exploring this repo, we can provide you ideas as to how to solve your own cluster's identity needs.

## What is in this lab

This lab will setup a single node Kubernetes cluster with:

1. Kubernetes Dashboard 2.0 beta
2. OpenUnison for authentication and automated provisioning (https://github.com/OpenUnison/openunison-k8s-activedirectory)
3. MariaDB as a database for OpenUnison
4. Postfix as a "black hole" for SMTP (doesn't work at the moment as intended)
5. Ingress NGINX controller
6. `pen` as the bare-metal load balancer

The lab will take you through integrating OpenUnison for SSO, enabling the Kubernetes audit log, debugging RBAC policies and setting up pod security policies.

## Pre Reqs

To run this lab you will need:

1. Active Directory domain controller configured with LDAPS
2. A read only service account for the domain controller
3. A user with a givenName, sn, samAccountName and mail attribute
4. The domain controller's certificate in PEM format
5. A VM with 2 processors and 4G of RAM with Ubuntu server 18.04 or better (NOT the live install)
6. A system with ansible on it to run the deployment playbook
7. An ssh key to copy

The playbooks were tested with http://cdimage.ubuntu.com/releases/18.04.3/release/ubuntu-18.04.3-server-amd64.iso as well as with VMs on DigitalOcean and AWS using their standard Ubuntu images.

## Deployment

*Copy your ssh key*
`ssh-copy-id user@x.x.x.x`

*Edit inventory.ini*
Replace the IP address with the IP of your server(s), update the variables with the correct information.

*Copy your PEM file to ldaps.pem*

*Run Playbook*
`ansible-playbook -i ./inventory.ini --user=user --extra-vars='ansible_sudo_pass=password'  deploy_all.yaml`

Grab some coffee, this will take 10-15 minutes to run.

# Labs

***NOTE*** At the moment Chrome doesn't seem to like the self signed certs in conjunction with nip.io addresses.  Use FireFox.

## Lab 1

### Login and initialize

1. https://ou.apps.IP.nip.io/
2. Login with the username / password - k8s-lab/$tart123
3. Logout
4. SSH to your server, user name `root` and this ssh key:
5. Make yourself an administrator `/usr/bin/mysql -u root -h $(/usr/bin/kubectl get svc -n mariadb -o json | /snap/bin/jq -r .items[0].spec.clusterIP) --password=start123 -e "insert into userGroups (userId,groupId) values (2,1);" unison`
6. Make yourself a cluster administrator `/usr/bin/mysql -u root -h $(/usr/bin/kubectl get svc -n mariadb -o json | /snap/bin/jq -r .items[0].spec.clusterIP) --password=start123 -e "insert into userGroups (userId,groupId) values (2,2);" unison`
7. Log back in
8. Click on *Kubernetes Dashboard*

### Enable SSO

1. SSH to your server
2. Get api server parameter flags `kubectl describe configmap api-server-config -n openunison`
3. Export CA certificate `kubectl get secret ou-tls-certificate -n openunison -o json | jq -r '.data."tls.crt"' | base64 -d > /etc/kubernetes/pki/ou-ca.pem`
4. Update `/etc/kubernetes/manifests/kube-apiserver.yaml` with output of #2
5. clear your k8s config `rm /root/.kube/config`
6. `kubectl get pods --all-namespaces`
7. Load token
8. `kubectl get pods --all-namespaces`
9. Logout of openunison
10. `watch kubectl get pods --all-namespaces`

## Lab 2

### Create Namespace

1. Login to your openunison with the user `makens` and the password `$tart123`
2. Setup kubectl using your token
3. Try to create a NS `kubectl create ns mynewns`, it will fail
4. Enable audit logging:
  a. `mkdir /var/log/k8s`
  b. `mkdir /etc/kubernetes/audit`
  c. `cp k8s-audit-policy.yaml /etc/kubernetes/audit`
  d. Edit `/etc/kubernetes/manifests/kube-apiserver.yaml`
    a.  add to `command`
    ```
    - --audit-log-path=/var/log/k8s/audit.log
    - --audit-log-maxage=1
    - --audit-log-maxbackup=10
    - --audit-log-maxsize=10
    - --audit-policy-file=/etc/kubernetes/audit/k8s-audit-policy.yaml
    ```
    a.  add:
    ```
    - mountPath: /var/log/k8s
      name: var-log-k8s
      readOnly: false
    - mountPath: /etc/kubernetes/audit
      name: etc-kubernetes-audit
      readOnly: true
    ```
    to `volumeMounts` section
    b. add:
    ```
    - hostPath:
        path: /var/log/k8s
        type: DirectoryOrCreate
      name: var-log-k8s
    - hostPath:
        path: /etc/kubernetes/audit
        type: DirectoryOrCreate
      name: etc-kubernetes-audit
    ```
    to `volumes`
    
5. Once the api server is running again, login as makens again and try creating a namespace again `kubectl create ns mynewns`, it will fail
6. Look for the audit logs message `grep makens /var/log/k8s/audit.log`
7. Generate RBAC rules from `audit2rbac`, replace `IP` with the IP of your cluster `./audit2rbac --filename=/var/log/k8s/audit.log --user=https://ou.apps.IP.nip.io/auth/idp/k8sIdp#makens > newrbac.yaml`
8.  Set your context to admin `export KUBECONFIG=/root/.kube/config-admin` 
9 . Import the RBAC `kubectl create -f ./newrbac.yaml`
10.  Unset your kubeconfig to go back to your default `export KUBECONFIG=`
11. kubectl create ns mynewns, SUCCESS!


## Lab 3

### Enable Pod Security Policies

1. Create the policies - `kubectl create -f ./podsecuritypolicies.yaml`
2. Edit `/etc/kubernetes/manifests/kube-apiserver.yaml`, change `--enable-admission-plugins=NodeRestriction` to `--enable-admission-plugins=PodSecurityPolicy,NodeRestriction`
3. Save
4. Delete all your pods `kubectl delete pods --all-namespaces --all`
5. Once done, check if OpenUnison is running and what policy its running under `kubectl describe pods -l application=openunison-orchestra -n openunison`
6. Chcek if tthe ingress pod is running `kubectl get pods -n ingress-nginx`
7. Check if mariadb is running `kubectl get pods -n mariadb`
8. Look at the events for both the `mariadb` and `ingress-nginx` namespace - `kubectl get events -n mariadb` / `kubectl get events -n ingress-nginx`
7. Why isn't it running? :
```
kubectl create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: privileged-psp
subjects:
# For the kubeadm kube-system nodes
- kind: ServiceAccount
  name: nginx-ingress-serviceaccount
  namespace: ingress-nginx
EOF
```
8. Update the ingress-nginx `Deployment` to force a redeploy - `kubectl edit deployment nginx-ingress-controller -n ingress-nginx`
9. Fix mariadb:
```
kubectl create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: mariadb
  namespace: mariadb
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: privileged-psp
subjects:
# For the kubeadm kube-system nodes
- kind: ServiceAccount
  name: default
  namespace: mariadb
EOF
```
