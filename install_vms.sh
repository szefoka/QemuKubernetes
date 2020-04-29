IP=$1
sudo apt update -y
sudo apt install -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager openvswitch-switch
sudo ovs-vsctl add-br ovsbr
sudo ifconfig ens1f1 0
sudo ovs-vsctl add-port ovsbr ens1f1
sudo ifconfig ovsbr $IP/24
