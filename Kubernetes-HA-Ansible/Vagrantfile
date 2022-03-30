# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure(2) do |config|


  # Load Balancer Node
  config.vm.define "loadbalancer" do |lb|
    lb.vm.box = "bento/ubuntu-20.04"
    lb.vm.hostname = "loadbalancer"
    lb.vm.network "private_network", ip: "172.16.16.100"
    lb.vm.provider "virtualbox" do |v|
      v.name = "loadbalancer"
      v.memory = 1024
      v.cpus = 1
    end
  end

  MasterCount = 3

  # Kubernetes Master Nodes
  (1..MasterCount).each do |i|
    config.vm.define "master#{i}" do |masternode|
      masternode.vm.box = "bento/ubuntu-20.04"
      masternode.vm.hostname = "master#{i}"
      masternode.ssh.password = "vagrant"
      masternode.vm.network "private_network", ip: "172.16.16.10#{i}"
      masternode.vm.provider "virtualbox" do |v|
        v.name = "master#{i}"
        v.memory = 2048
        v.cpus = 2
      end
#      masternode.vm.provision "ansible_local" do |ansible|
#        ansible.playbook = "kubernetes-setup/masters-playbook.yml"
#      end

    end
  end

  NodeCount = 3

  # Kubernetes Worker Nodes
  (1..NodeCount).each do |i|
    config.vm.define "worker#{i}" do |workernode|
      workernode.vm.box = "bento/ubuntu-20.04"
      workernode.ssh.password = "vagrant"
      workernode.vm.hostname = "worker#{i}"
      workernode.vm.network "private_network", ip: "172.16.16.10#{i+3}"
      workernode.vm.provider "virtualbox" do |v|
        v.name = "worker#{i}"
        v.memory = 1024
        v.cpus = 1
      end
#      workernode.vm.provision "ansible_local" do |ansible|
#        ansible.playbook = "kubernetes-setup/nodes-playbook.yml"
#y      end
    end
  end

end