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
runcmd:
  - [ bash, -c, "apt-get install -y apt-transport-https ca-certificates curl gpg git jq" ]
  - [ bash, -c, "mkdir -p /etc/apt/keyrings && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg" ]
  - [ bash, -c, "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' > /etc/apt/sources.list.d/kubernetes.list" ]
  - [ bash, -c, "apt-get update" ]
  - [ bash, -c, "apt-get install -y kubectl" ]
  - [ bash, -c, "curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash" ]
  - [ bash, -c, "curl -fsSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && chmod +x /usr/local/bin/argocd" ]
  - [ bash, -c, "mkdir -p /home/${ssh_user}/.kube && chown -R ${ssh_user}:${ssh_user} /home/${ssh_user}/.kube" ]
  - [ bash, -c, "echo 'Copy admin.conf from the control plane to ~/.kube/config to use kubectl.' > /etc/motd" ]
