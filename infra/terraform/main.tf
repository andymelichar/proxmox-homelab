locals {
  netmask = cidrnetmask(var.network_cidr)

  control_planes = {
    for idx, ip in slice(var.control_plane_ips, 0, var.control_plane_count) :
    format("cp%d", idx + 1) => ip
  }

  workers = {
    for idx, ip in slice(var.worker_ips, 0, var.worker_count) :
    format("w%d", idx + 1) => ip
  }
}

resource "null_resource" "control_plane_cloudinit" {
  for_each = local.control_planes

  connection {
    type        = "ssh"
    host        = var.proxmox_ssh_host
    user        = var.proxmox_ssh_user
    private_key = file(var.proxmox_ssh_private_key_path)
  }

  provisioner "file" {
    content = templatefile(
      "${path.module}/../cloud-init/control-plane.yaml.tpl",
      {
        hostname                 = format("k8s-%s", each.key)
        ssh_user                 = var.ssh_user
        ssh_public_key           = var.ssh_public_key
        apiserver_advertise_addr = each.value
        control_plane_endpoint   = var.control_plane_endpoint
        pod_cidr                 = var.pod_cidr
        kubeadm_token            = var.kubeadm_token
        k8s_minor_version        = var.k8s_minor_version
        cni_manifest             = var.cni_manifest
        metrics_server_manifest  = var.metrics_server_manifest
      }
    )
    destination = format("%s/k8s-%s-cloudinit.yml", var.cloudinit_snippets_path, each.key)
  }
}

resource "null_resource" "worker_cloudinit" {
  for_each = local.workers

  connection {
    type        = "ssh"
    host        = var.proxmox_ssh_host
    user        = var.proxmox_ssh_user
    private_key = file(var.proxmox_ssh_private_key_path)
  }

  provisioner "file" {
    content = templatefile(
      "${path.module}/../cloud-init/worker.yaml.tpl",
      {
        hostname                = format("k8s-%s", each.key)
        ssh_user                = var.ssh_user
        ssh_public_key          = var.ssh_public_key
        control_plane_endpoint  = var.control_plane_endpoint
        kubeadm_token           = var.kubeadm_token
        pod_cidr                = var.pod_cidr
        k8s_minor_version       = var.k8s_minor_version
      }
    )
    destination = format("%s/k8s-%s-cloudinit.yml", var.cloudinit_snippets_path, each.key)
  }
}

resource "null_resource" "jumphost_cloudinit" {
  count = 1

  connection {
    type        = "ssh"
    host        = var.proxmox_ssh_host
    user        = var.proxmox_ssh_user
    private_key = file(var.proxmox_ssh_private_key_path)
  }

  provisioner "file" {
    content = templatefile(
      "${path.module}/../cloud-init/jumphost.yaml.tpl",
      {
        hostname       = "jumphost"
        ssh_user       = var.ssh_user
        ssh_public_key = var.ssh_public_key
      }
    )
    destination = format("%s/jumphost-cloudinit.yml", var.cloudinit_snippets_path)
  }
}

resource "proxmox_vm_qemu" "jumphost" {
  name        = "jumphost"
  target_node = var.proxmox_node
  clone       = var.base_vm_template
  pool        = null

  agent  = 1
  onboot = true

  cores   = var.jumphost_cores
  memory  = var.jumphost_memory_mb
  sockets = 1
  scsihw  = "virtio-scsi-pci"
  tags    = "jumphost;ephemeral"

  disk {
    size    = format("%dG", var.jumphost_disk_gb)
    type    = "scsi"
    storage = var.vm_storage
  }

  network {
    model  = "virtio"
    bridge = var.vm_bridge
  }

  ipconfig0 = format("ip=%s/%s,gw=%s", var.jumphost_ip, local.netmask, var.gateway)
  ciuser    = var.ssh_user
  sshkeys   = var.ssh_public_key
  cicustom  = format("user=%s:snippets/jumphost-cloudinit.yml", var.cloudinit_storage)

  depends_on = [null_resource.jumphost_cloudinit]
}

resource "proxmox_vm_qemu" "control_plane" {
  for_each = local.control_planes

  name        = format("k8s-%s", each.key)
  target_node = var.proxmox_node
  clone       = var.base_vm_template
  pool        = null

  agent  = 1
  onboot = true

  cores   = var.control_plane_cores
  memory  = var.control_plane_memory_mb
  sockets = 1
  scsihw  = "virtio-scsi-pci"
  tags    = "k8s;control-plane;ephemeral"

  disk {
    size    = format("%dG", var.control_plane_disk_gb)
    type    = "scsi"
    storage = var.vm_storage
  }

  network {
    model  = "virtio"
    bridge = var.vm_bridge
  }

  ipconfig0 = format("ip=%s/%s,gw=%s", each.value, local.netmask, var.gateway)
  ciuser    = var.ssh_user
  sshkeys   = var.ssh_public_key
  cicustom  = format("user=%s:snippets/k8s-%s-cloudinit.yml", var.cloudinit_storage, each.key)

  depends_on = [null_resource.control_plane_cloudinit]
}

resource "proxmox_vm_qemu" "worker" {
  for_each = local.workers

  name        = format("k8s-%s", each.key)
  target_node = var.proxmox_node
  clone       = var.base_vm_template
  pool        = null

  agent  = 1
  onboot = true

  cores   = var.worker_cores
  memory  = var.worker_memory_mb
  sockets = 1
  scsihw  = "virtio-scsi-pci"
  tags    = "k8s;worker;ephemeral"

  disk {
    size    = format("%dG", var.worker_disk_gb)
    type    = "scsi"
    storage = var.vm_storage
  }

  network {
    model  = "virtio"
    bridge = var.vm_bridge
  }

  ipconfig0 = format("ip=%s/%s,gw=%s", each.value, local.netmask, var.gateway)
  ciuser    = var.ssh_user
  sshkeys   = var.ssh_public_key
  cicustom  = format("user=%s:snippets/k8s-%s-cloudinit.yml", var.cloudinit_storage, each.key)

  depends_on = [
    null_resource.worker_cloudinit,
    proxmox_vm_qemu.control_plane
  ]
}
