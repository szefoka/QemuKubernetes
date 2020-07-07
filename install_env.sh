nodes=(hp186.utah.cloudlab.us-10.0.0.1 hp196.utah.cloudlab.us-10.0.0.2 hp197.utah.cloudlab.us-10.0.0.3 hp169.utah.cloudlab.us-10.0.0.4)

cat /dev/zero | ssh-keygen -q -N "" -f vmkey

for i in ${nodes[*]}
do
  NODE=$(echo $i | cut -d "-" -f 1)
  INTERNAL_IP=$(echo $i | cut -d "-" -f 2)
  scp -i ~/.ssh/cloudlab -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null vmkey* szefoka@$NODE:.ssh/
  ssh szefoka@$NODE -i ~/.ssh/cloudlab -o "StrictHostKeyChecking no" "bash -s" < ./install_vms.sh $INTERNAL_IP
done

INTERNAL_NODE_ID="0"
for i in ${nodes[@]}
do
  NODE=$(echo $i | cut -d "-" -f 1)
  if [[ ( "$INTERNAL_NODE_ID" == "0" ) ]]
  then
    ssh szefoka@$NODE -i ~/.ssh/cloudlab -o "StrictHostKeyChecking no" "bash -s" < ./create_vm.sh master 10.0.0.$((10+$INTERNAL_NODE_ID))
    INTERNAL_NODE_ID=$((INTERNAL_NODE_ID+1))
  else
    ssh szefoka@$NODE -i ~/.ssh/cloudlab -o "StrictHostKeyChecking no" "bash -s" < ./create_vm.sh worker$INTERNAL_NODE_ID 10.0.0.$((10+$INTERNAL_NODE_ID))
    INTERNAL_NODE_ID=$((INTERNAL_NODE_ID+1))
  fi
  ssh szefoka@$NODE -i ~/.ssh/cloudlab -o "StrictHostKeyChecking no" "bash -s" < ./create_vm.sh worker$INTERNAL_NODE_ID 10.0.0.$((10+$INTERNAL_NODE_ID))
  INTERNAL_NODE_ID=$((INTERNAL_NODE_ID+1))
done

