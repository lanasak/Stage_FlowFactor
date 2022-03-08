# Kubernetes HA cluster setup using ansible and vagrant
1 Load Balancer Node  
3 Kubernetes Master Nodes  
3 Kubernetes Worker Nodes

## Vagrant Environment
|Role|FQDN|IP|OS|RAM|CPU|
|----|----|----|----|----|----|
|Load Balancer|loadbalancer1|172.16.16.100|Ubuntu 20.04|1024M|1|
|Master|master1|172.16.16.101|Ubuntu 20.04|2048M|2|
|Master|master2|172.16.16.102|Ubuntu 20.04|2048M|2|
|Master|master3|172.16.16.103|Ubuntu 20.04|2048M|2|
|Worker|worker1|172.16.16.104|Ubuntu 20.04|1024M|1|
|Worker|worker2|172.16.16.105|Ubuntu 20.04|1024M|1|
|Worker|worker3|172.16.16.106|Ubuntu 20.04|1024M|1|

## Pre-requisites
If you want to try this in a virtualized environment on your workstation
* Virtualbox installed
* Vagrant installed

## Bring up all the virtual machines
```
vagrant up
```
## Downloading kube config to your local machine
On your host machine
```
mkdir ~/.kube
scp root@172.16.16.101:/etc/kubernetes/admin.conf ~/.kube/config
```

## Verifying the cluster
```
kubectl cluster-info
kubectl get nodes
kubectl get cs
```
