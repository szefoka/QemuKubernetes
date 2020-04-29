#Installing Docker, we need a registry on the physical master
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

sudo ./docker_registry_setup.sh host

WORKER_VMS=(10.0.0.11 10.0.0.12 10.0.0.13 10.0.0.14 10.0.0.15 10.0.0.16 10.0.0.17)

ssh -i /users/szefoka/.ssh/vmkey -o "StrictHostKeyChecking no" ubuntu@10.0.0.10 "bash -s" < ./kube_install.sh
ssh -i /users/szefoka/.ssh/vmkey -o "StrictHostKeyChecking no" ubuntu@10.0.0.10 "bash -s" < ./docker_registry_setup.sh

sleep 10
TOKEN=$(ssh -i /users/szefoka/.ssh/vmkey -o "StrictHostKeyChecking no" ubuntu@10.0.0.10 sudo kubeadm token list | tail -n 1 | cut -d ' ' -f 1)
HASH=sha256:$(ssh -i /users/szefoka/.ssh/vmkey -o "StrictHostKeyChecking no" ubuntu@10.0.0.10 openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')

for VM in "${WORKER_VMS[@]}"
do
  ssh-keygen -f "/users/szefoka/.ssh/known_hosts" -R "$VM"
  ssh -o "StrictHostKeyChecking no" -i /users/szefoka/.ssh/vmkey ubuntu@$VM "bash -s" < ./kube_install.sh true 10.0.0.10:6443 $TOKEN $HASH
  ssh -o "StrictHostKeyChecking no" -i /users/szefoka/.ssh/vmkey ubuntu@$VM "bash -s" < ./docker_registry_setup.sh
done
