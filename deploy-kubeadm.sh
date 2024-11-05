apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg gnupg2
#curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
#cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
#deb https://apt.kubernetes.io/ kubernetes-xenial main
#EOF
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' |  tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get -y upgrade
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-get update
apt-get -y upgrade
apt-get update
apt-mark hold kubelet kubeadm kubectl
