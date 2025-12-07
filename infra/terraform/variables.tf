variable "proxmox_url" {
  description = "Proxmox API endpoint, e.g. https://proxmox.example:8006/api2/json"
  type        = string
}

variable "proxmox_user" {
  description = "Proxmox username, e.g. root@pam or api@pve"
  type        = string
}

variable "proxmox_token_id" {
  description = "Proxmox API token id"
  type        = string
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Allow insecure TLS to Proxmox"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Target Proxmox node name"
  type        = string
}

variable "proxmox_ssh_host" {
  description = "Proxmox host/IP used to push cloud-init snippets via SSH"
  type        = string
}

variable "proxmox_ssh_user" {
  description = "SSH user for Proxmox host"
  type        = string
  default     = "root"
}

variable "proxmox_ssh_private_key_path" {
  description = "Path to SSH private key for Proxmox host (used by file provisioner)"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "base_vm_template" {
  description = "Proxmox VM template name built from a cloud image (e.g. ubuntu-2204-cloudinit)"
  type        = string
}

variable "cloudinit_snippets_path" {
  description = "Absolute path on Proxmox where snippets live (usually /var/lib/vz/snippets)"
  type        = string
  default     = "/var/lib/vz/snippets"
}

variable "cloudinit_storage" {
  description = "Storage id that holds cloud-init snippets (e.g. local)"
  type        = string
  default     = "local"
}

variable "vm_bridge" {
  description = "Proxmox bridge to attach VMs"
  type        = string
  default     = "vmbr0"
}

variable "vm_storage" {
  description = "Proxmox storage target for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "ssh_user" {
  description = "Default SSH/k8s user"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key injected into VMs"
  type        = string
}

variable "network_cidr" {
  description = "CIDR for VM network, used to derive netmask"
  type        = string
}

variable "gateway" {
  description = "Gateway IP for VM network"
  type        = string
}

variable "jumphost_ip" {
  description = "Static IP for jumphost"
  type        = string
}

variable "control_plane_ips" {
  description = "List of control plane node IPs (first N used)"
  type        = list(string)
}

variable "worker_ips" {
  description = "List of worker node IPs (first N used)"
  type        = list(string)
}

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "control_plane_cores" {
  description = "vCPU count per control plane"
  type        = number
  default     = 4
}

variable "worker_cores" {
  description = "vCPU count per worker"
  type        = number
  default     = 4
}

variable "jumphost_cores" {
  description = "vCPU count for jumphost"
  type        = number
  default     = 2
}

variable "control_plane_memory_mb" {
  description = "RAM per control plane (MB)"
  type        = number
  default     = 8192
}

variable "worker_memory_mb" {
  description = "RAM per worker (MB)"
  type        = number
  default     = 8192
}

variable "jumphost_memory_mb" {
  description = "RAM for jumphost (MB)"
  type        = number
  default     = 4096
}

variable "control_plane_disk_gb" {
  description = "Disk size per control plane (GB)"
  type        = number
  default     = 120
}

variable "worker_disk_gb" {
  description = "Disk size per worker (GB)"
  type        = number
  default     = 120
}

variable "jumphost_disk_gb" {
  description = "Disk size for jumphost (GB)"
  type        = number
  default     = 40
}

variable "pod_cidr" {
  description = "Pod CIDR for kubeadm"
  type        = string
  default     = "10.244.0.0/16"
}

variable "kubeadm_token" {
  description = "Pre-shared kubeadm token used for init/join (must match kubeadm token format)"
  type        = string
  default     = "abcdef.0123456789abcdef"
}

variable "control_plane_endpoint" {
  description = "Control plane endpoint or IP workers will join"
  type        = string
}

variable "k8s_minor_version" {
  description = "Kubernetes minor version used for apt repo (e.g. 1.30)"
  type        = string
  default     = "1.30"
}

variable "cni_manifest" {
  description = "CNI manifest URL applied after kubeadm init"
  type        = string
  default     = "https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml"
}

variable "metrics_server_manifest" {
  description = "Metrics server manifest URL"
  type        = string
  default     = "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
}
