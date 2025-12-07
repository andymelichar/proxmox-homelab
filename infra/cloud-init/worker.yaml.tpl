#cloud-config
hostname: ${hostname}
manage_etc_hosts: true
users:
  - name: ${ssh_user}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_public_key}
package_update: true
package_upgrade: true
write_files:
  - path: /etc/modules-load.d/k8s.conf
    content: |
      overlay
      br_netfilter
  - path: /etc/sysctl.d/k8s.conf
    content: |
      net.bridge.bridge-nf-call-iptables = 1
      net.bridge.bridge-nf-call-ip6tables = 1
      net.ipv4.ip_forward = 1
runcmd:
  - [ bash, -c, "swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab" ]
  - [ bash, -c, "modprobe overlay && modprobe br_netfilter" ]
  - [ bash, -c, "sysctl --system" ]
  - [ bash, -c, "apt-get install -y apt-transport-https ca-certificates curl gpg" ]
  - [ bash, -c, "mkdir -p /etc/apt/keyrings && curl -fsSL https://pkgs.k8s.io/core:/stable:/v${k8s_minor_version}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg" ]
  - [ bash, -c, "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${k8s_minor_version}/deb/ /' > /etc/apt/sources.list.d/kubernetes.list" ]
  - [ bash, -c, "apt-get update" ]
  - [ bash, -c, "apt-get install -y kubelet kubeadm kubectl containerd" ]
  - [ bash, -c, "apt-mark hold kubelet kubeadm kubectl" ]
  - [ bash, -c, "containerd config default | tee /etc/containerd/config.toml" ]
  - [ bash, -c, "sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml" ]
  - [ bash, -c, "systemctl enable --now containerd" ]
  - [ bash, -c, "systemctl enable --now kubelet" ]
  - [ bash, -c, "kubeadm join ${control_plane_endpoint}:6443 --token ${kubeadm_token} --discovery-token-unsafe-skip-ca-verification" ]
