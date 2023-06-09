apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg gnupg2
#curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
#cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
#deb https://apt.kubernetes.io/ kubernetes-xenial main
#EOF
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg add
echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get -y upgrade
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-get update
apt-get -y upgrade
apt-get update
apt-mark hold kubelet kubeadm kubectl
