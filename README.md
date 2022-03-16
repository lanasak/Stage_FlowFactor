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
## Set up load balancer node  
### Install and configure haproxy
##### Install Haproxy
haproxy_installation.yml
```
---
- name: Generate Hosts File
  hosts: haproxy
  become: true
  gather_facts: true
  vars:
    my_file: /etc/haproxy/haproxy.cfg
    my_template: templates/haproxy.j2
  tasks:
    - name: Install haproxy
      apt: name=haproxy state=present
    - name: Create "{{ my_file }}"
      template:
        src: "{{ my_template }}"
        dest: "{{ my_file }}"
        owner: root
        group: root
        mode: "0644"
    - name: start haproxy service
      service:
        name: haproxy
        state: started

 ```
 ##### Configure haproxy
  **haproxy template**
```
frontend k8s-api
   bind 172.16.16.100:6443
   mode tcp
   option tcplog
   default_backend k8s-api

backend k8s-api
   mode tcp
   option tcplog
   option tcp-check
   balance roundrobin
   default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

       server master1   172.16.16.101:6443 check
       server master2   172.16.16.102:6443 check
       server master3   172.16.16.103:6443 check
```
 ## Set up master nodes
 #### prerequisites
 **kubernetes_master_prerequisites.yml**
```
---
- name: Generate Hosts File
  hosts: masters
  become: true
  gather_facts: true
  tasks:
    - name: Installing Prerequisites for Kubernetes
      apt: 
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg-agent
          - vim
          - software-properties-common
          - policycoreutils
        state: present

    - name: Add an apt signing key for Docker
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add apt repository for stable version
      apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable
        state: present

    - name: Execute the script
      command: sh /vagrant/docker.sh
 
    - name: Start Docker service
      service:
        name: docker
        state: started
        enabled: yes
      become: yes

    - name: Disable SELinux
      selinux:
        state: disabled
      register: result
      failed_when: result.msg | default('ok', True) is not search('(^ok$|libselinux-python|(SELinux state changed))')
    - name: Disable SWAP
      command: swapoff -a

    - name: add Kubernetes apt-key for APT repository
      apt_key:
        url: https://packages.cloud.google.com/apt/doc/apt-key.gpg
        state: present

    - name: add Kubernetes APT repository
      apt_repository:
        repo: deb http://apt.kubernetes.io/ kubernetes-xenial main
        state: present
        filename: 'kubernetes'

    - name: Install Kubernetes Package
      command: sh /vagrant/kubernetes.sh

    - name: Enable / Start kubelet Service
      service:
        name: kubelet
        state: started
        enabled: yes
    - name: Letting iptables see bridged traffic
      copy:
        src: /vagrant/files/k8s.conf
        dest: /etc/sysctl.d/k8s.conf
        owner: root
        group: root
        mode: '0644'
    - name: Reload sysctl config for iptables
      command: sysctl --system
```


 #### Choose master leader
  Choose master leader and copy tokens to ./token  
 **leader_master.yml**  
```
---
- name: Generate Hosts File
  hosts: leader
  become: true
  gather_facts: true
  vars:
    nodeip: var=ansible_eth1.ipv4.address
  tasks:
    - name: Initializing Kubernetes cluster
      shell: kubeadm init --control-plane-endpoint 172.16.16.100:6443 --upload-certs --apiserver-advertise-address 172.16.16.101  --pod-network-cidr 192.168.0.0/16 --service-cidr 192.168.2.0/24
      register: output
    - name: Storing Logs and Generated token for future purpose.
      local_action: copy content={{ output.stdout }} dest="./token"
    - name: Copying required files
      shell: |
        mkdir -p $HOME/.kube
        sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
    - name: Install calico pod network
      shell: kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.15/manifests/calico.yaml


```
In ./token there are the tokens to join control-plane nodes (master2, master3) and worker nodes (worker1, worker2, worker3)

#### Join master nodes to the cluster (master2, master3)
1- Copy master token from ./token and to ./mastertoken   
2- Run join-command  
**master_member.yml**
```
---
- name: Generate Hosts File
  hosts: member
  become: true
  gather_facts: true
  tasks:
    - name: Usesystemd
      command: sh /vagrant/usesystemd.sh
    - name: Generated token - 1.
      local_action: shell sed -n 69,72p ./token > ./mastertoken
    - name: Copy master token
      copy:
        src: /vagrant/mastertoken
        dest: /tmp/join-command.sh
        owner: root
        group: root
        mode: '0777'
    - name: Generated token - 2.
      lineinfile:
        path: /tmp/join-command.sh
        line: '\ --apiserver-advertise-address {{ hostvars[inventory_hostname].ansible_eth1.ipv4.address}}'

    - name: Add new Kubernetes master member
      command: sh /tmp/join-command.sh

```
## Set up worker nodes
 #### prerequisites
 **kubernetes_worker_prerequisites.yml**
```
---
- name: Generate Hosts File
  hosts: worker
  become: true
  gather_facts: true
  tasks:
    - name: Installing Prerequisites for Kubernetes
      apt: 
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg-agent
          - vim
          - software-properties-common
          - policycoreutils
        state: present

    - name: Add an apt signing key for Docker
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add apt repository for stable version
      apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable
        state: present

    - name: Execute the script
      command: sh /vagrant/docker.sh
 
    - name: Start Docker service
      service:
        name: docker
        state: started
        enabled: yes
      become: yes

    - name: Disable SELinux
      selinux:
        state: disabled
      register: result
      failed_when: result.msg | default('ok', True) is not search('(^ok$|libselinux-python|(SELinux state changed))')
    - name: Disable SWAP
      command: swapoff -a

    - name: add Kubernetes apt-key for APT repository
      apt_key:
        url: https://packages.cloud.google.com/apt/doc/apt-key.gpg
        state: present

    - name: add Kubernetes APT repository
      apt_repository:
        repo: deb http://apt.kubernetes.io/ kubernetes-xenial main
        state: present
        filename: 'kubernetes'

    - name: Install Kubernetes Package
      command: sh /vagrant/kubernetes.sh
    - name: Enable / Start kubelet Service
      service:
        name: kubelet
        state: started
        enabled: yes
    - name: Letting iptables see bridged traffic
      copy:
        src: /vagrant/files/k8s.conf
        dest: /etc/sysctl.d/k8s.conf
        owner: root
        group: root
        mode: '0644'
    - name: Reload sysctl config for iptables
      command: sysctl --system

```
#### Join worker nodes to the cluster (worker1, worker2, worker3)
1- Copy worker token from ./token and to ./workertoken  
2- Run join-worker-command  
**join-worker-machine.yml**
```
---
- name: Generate Hosts File
  hosts: worker
  become: true
  gather_facts: true
  tasks:
    - name: Generated token - 1.
      local_action: shell sed -n 79,81p ./token > ./workertoken
    - name: Copy master token
      copy:
        src: /vagrant/workertoken
        dest: /tmp/join-worker-command.sh
        owner: root
        group: root
        mode: '0777'
    - name: Add new Kubernetes master member
      command: sh /tmp/join-worker-command.sh

```
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
