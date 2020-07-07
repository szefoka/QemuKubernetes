IP=$2

echo Hello

sudo virsh destroy $1
sudo virsh undefine $1

cd /mnt

if [ ! -f ubuntu-16.04.qcow2 ]; then
    sudo wget https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
    sudo mv xenial-server-cloudimg-amd64-disk1.img ubuntu-16.04.qcow2
fi

sudo qemu-img create -f qcow2 -o backing_file=ubuntu-16.04.qcow2 $1.qcow2
sudo qemu-img resize $1.qcow2 50G

sudo cat >meta-data <<EOF
local-hostname: $1
EOF

export PUB_KEY=$(cat /users/szefoka/.ssh/vmkey.pub)

sudo cat >user-data <<EOF
#cloud-config
users:
  - name: ubuntu
    ssh-authorized-keys:
      - $PUB_KEY
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
runcmd:
  - echo "AllowUsers ubuntu root" >> /etc/ssh/sshd_config
  - restart ssh

  - echo "10.0.0.10 master" >> /etc/hosts
  - echo "10.0.0.11 worker1" >> /etc/hosts
  - echo "10.0.0.12 worker2" >> /etc/hosts
  - echo "10.0.0.13 worker3" >> /etc/hosts
  - echo "10.0.0.14 worker4" >> /etc/hosts
  - echo "10.0.0.15 worker5" >> /etc/hosts
  - echo "10.0.0.16 worker6" >> /etc/hosts
  - echo "10.0.0.17 worker7" >> /etc/hosts

  - echo "auto ens3" >> /etc/network/interfaces.d/50-cloud-init.cfg
  - echo "iface ens3 inet static" >> /etc/network/interfaces.d/50-cloud-init.cfg
  - echo "address $IP" >> /etc/network/interfaces.d/50-cloud-init.cfg
  - echo "netmask 255.255.255.0" >> /etc/network/interfaces.d/50-cloud-init.cfg
  - /etc/init.d/networking restart
EOF

sudo genisoimage  -output $1-cidata.iso -volid cidata -joliet -rock user-data meta-data

sudo virt-install --connect qemu:///system --virt-type kvm --name $1 --ram 10240 --vcpus=8 --os-type linux --os-variant ubuntu16.04 --disk path=$1.qcow2,format=qcow2 --disk $1-cidata.iso,device=cdrom --import --network network=default --network=bridge:ovsbr,model=virtio,virtualport_type=openvswitch --graphics none --noautoconsole


