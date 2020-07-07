sudo  sh -c 'sed "/ExecStart/ s/$/ --insecure-registry=10.0.0.10:5000/" /lib/systemd/system/docker.service > /lib/systemd/system/tmp'
sudo mv /lib/systemd/system/tmp /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl restart docker.service

#if [ "$1" = "host" ]
#then
#  sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2
#fi

if [ "$1" = "master" ]
then
  sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2
fi
