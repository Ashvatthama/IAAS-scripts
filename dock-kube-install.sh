#!/bin/bash
echo "NOTE: Don't run the script with 'sudo'"

function docker(){
sudo apt-get update
sudo apt-get upgrade -y
echo "[*] Installing Docker"
sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual -y
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
sudo apt-get update
sudo apt-get install -y docker-ce --allow-unauthenticated
sudo usermod -aG docker $USER
}

function k8s(){
if [[ -z `cat /etc/lsb-release | grep 16.04` ]]; then
  echo "[-] Exiting installation of Kubernetes(with kubeadm) which requries Ubuntu 16.04"
  exit 1
fi
sudo apt-get install -y apt-transport-https
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni --allow-unauthenticated
FIND_IP="http://checkip.amazonaws.com/"
PUBLIC_IP=`curl -s "$FIND_IP"`
if [[ -n "$PUBLIC_IP" ]]; then
  echo "[+] Your Public IP: $PUBLIC_IP"
  sudo iptables -P FORWARD ACCEPT
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$PUBLIC_IP --apiserver-bind-port=443 --skip-preflight-checks
else
  echo "[-] Not able to find your public IP."
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --skip-preflight-checks
fi
echo "[*] Placing kubeconfig file in ~/.kube/"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "[*] Making master node schedulable"
kubectl taint nodes --all node-role.kubernetes.io/master-
echo "[*] Applying 'Flannel' network to Kubernetes"
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.0/Documentation/kube-flannel.yml
#kubectl create clusterrolebinding anonymous-cluster-admin-binding --clusterrole=cluster-admin --user=system:anonymous
#echo "Launching cAdvisor Container"
#sudo docker run \
#  --volume=/:/rootfs:ro \
#  --volume=/var/run:/var/run:rw \
#  --volume=/sys:/sys:ro \
#  --volume=/var/lib/docker/:/var/lib/docker:ro \
#  --volume=/dev/disk/:/dev/disk:ro \
#  --publish=9090:8080 \
#  --detach=true \
#  --name=cadvisor \
#  --restart always \
#  google/cadvisor:latest
#echo ""
#echo "**===============IMPORT NOTE===============**"
#echo "1. PLEASE DO CHANGES AS SPECIFIED in https://goo.gl/fMLVEA"
#echo "2. Restart kubelet daemon"
#echo "3. RUN==> kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.0/Documentation/kube-flannel.yml"

#kubectl create -f https://raw.githubusercontent.com/coreos/flannel/v0.8.0/Documentation/kube-flannel-rbac.yml
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
#kubectl get pods --all-namespaces
#echo ""
#kubectl cluster-info
#echo ""
#sudo docker run --net=host --volume=/var/lib/docker/:/var/lib/docker:ro --volume=/sys/fs/cgroup/:/sys/fs/cgroup/:ro -it --name=opsmx-collector -d opsmx11/tcollector
echo "[*] Done"
echo "To remove, run below commands"
echo "kubectl drain <node name> --delete-local-data --force --ignore-daemonsets"
echo "kubectl delete node <node name>"
echo "kubeadm reset"

}

echo "Choose your options to install"
echo "1. Docker"
echo "2. Kubernetes"
echo "3. Both"
read response
case "$response" in
   "1") docker
        exit 0
   ;;
   "2") k8s
        exit 0
   ;;
   "3") docker
        k8s
		exit 0
   ;;
esac
