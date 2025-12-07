output "jumphost_ip" {
  description = "Jumphost IP"
  value       = var.jumphost_ip
}

output "control_plane_ips" {
  description = "Control plane IPs"
  value       = [for _, ip in local.control_planes : ip]
}

output "worker_ips" {
  description = "Worker IPs"
  value       = [for _, ip in local.workers : ip]
}

output "kubeadm_join_command" {
  description = "Static join command used by workers"
  value       = format("kubeadm join %s:6443 --token %s --discovery-token-unsafe-skip-ca-verification", var.control_plane_endpoint, var.kubeadm_token)
}
