# Proxmox Homelab: Jumphost + Kubernetes + ArgoCD

Ephemeral homelab stack for an HP Z440 running Proxmox: Terraform builds a jumphost plus kubeadm-based cluster, cloud-init bootstraps nodes, and ArgoCD handles GitOps.

## Prereqs
- Proxmox API token with VM + storage rights.
- Cloud-init VM template (e.g., Ubuntu 22.04) on Proxmox.
- Snippets storage enabled (default `/var/lib/vz/snippets`) and reachable over SSH for file upload.
- Terraform >= 1.5, `ssh` access to the Proxmox host, and your SSH public key.

## Layout
- `infra/terraform/` – Proxmox VM definitions, cloud-init upload, sample tfvars.
- `infra/cloud-init/` – Control-plane, worker, and jumphost user-data templates.
- `k8s/bootstrap/cluster-bootstrap.sh` – Applies ArgoCD and the root App-of-Apps after kubeconfig is in place.
- `gitops/argocd/root-app.yaml` – App-of-Apps that deploys everything under `apps/`.
- `apps/` – ArgoCD Applications (Longhorn, ingress-nginx, sample guestbook).

## Quickstart
1) Copy and edit `infra/terraform/terraform.tfvars.example` -> `terraform.tfvars` with your IPs, template name, token, and SSH key.
2) `cd infra/terraform && terraform init`.
3) `terraform apply -auto-approve` to create the jumphost + cluster VMs. Cloud-init snippets are pushed to the Proxmox host via SSH before VMs start.
4) After the control plane is up, copy kubeconfig to the jumphost (or your workstation):
   - `scp ubuntu@<control-plane-ip>:/etc/kubernetes/admin.conf ~/.kube/config`
5) From the jumphost (or anywhere with kubeconfig), run `k8s/bootstrap/cluster-bootstrap.sh` to install ArgoCD and the App-of-Apps.
6) Watch ArgoCD sync apps: `kubectl get applications -n argocd`.

## Notes and tweaks
- Control plane and workers use a pre-shared kubeadm token (`kubeadm_token`); adjust if desired.
- `control_plane_endpoint` is used by workers for `kubeadm join`; set it to the control-plane IP or a VIP if you add HA.
- Longhorn assumes space at `/var/lib/longhorn`; point `defaultDataPath` to another disk if you present one.
- CNI defaults to Calico; override `cni_manifest` in tfvars to swap to Cilium or another CNI.
- For a clean rebuild: `terraform destroy -auto-approve && terraform apply -auto-approve`.

## Next steps
- Wire in TLS + DNS (e.g., cert-manager + external-dns) via additional ArgoCD Applications.
- Add Argo Workflows/Events and a local registry on the jumphost if you want build pipelines inside the cluster.
