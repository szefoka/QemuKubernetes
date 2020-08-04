CLIENT=$1
IP=$2
TOKEN=$3
HASH=$4

#Installing Docker
DOCKER_INSTALLED=$(which docker)
if [ "$DOCKER_INSTALLED" = "" ]
then
	export DEBIAN_FRONTEND=noninteractive
	sudo apt-get remove docker docker-engine docker.io
	sudo apt-get update
	sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	sudo apt-get update -y
	sudo apt-get install -y docker-ce
fi

#Installing Kubernetes
KUBERNETES_INSTALLED=$(which kubeadm)
if [ "$KUBERNETES_INSTALLED" = "" ]
then
	export DEBIAN_FRONTEND=noninteractive
	sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
	sudo touch /etc/apt/sources.list.d/kubernetes.list
	sudo chmod 666 /etc/apt/sources.list.d/kubernetes.list
	sudo echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list
	sudo apt-get update -y
	sudo apt-get install -y kubelet=1.15.4-00 kubeadm=1.15.4-00 kubectl=1.15.4-00 kubernetes-cni
fi

sudo sysctl net.bridge.bridge-nf-call-iptables=1
sudo swapoff -a

if [ -z "$CLIENT" ]
then
	sudo sed -i '${s/$/ --node-ip 10.0.0.10/}' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
	sudo systemctl daemon-reload && sudo systemctl restart kubelet
	sleep 5
	sudo kubeadm init --ignore-preflight-errors=SystemVerification --pod-network-cidr 10.32.0.0/16 --apiserver-advertise-address 10.0.0.10 
	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config
	#install podnetwork
	sudo kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

elif [ "$CLIENT" = "true" ]
then
	NODE_IP=$(ip a show dev ens3 | grep inet | grep -v inet6 | awk '{print $2}' | cut -d "/" -f 1)
	sudo sed -i '${s/$/ --node-ip '"$NODE_IP"'/}' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
	sudo systemctl daemon-reload && sudo systemctl restart kubelet
	sleep 5
	sudo kubeadm join $IP --token $TOKEN --discovery-token-ca-cert-hash $HASH --ignore-preflight-errors=SystemVerification

	echo "Client joined to Master"
else
	echo "Invalid argument"
fi
