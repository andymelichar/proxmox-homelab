#!/usr/bin/env bash
set -euo pipefail

# Simple helper to create a Proxmox cloud-init template from an Ubuntu cloud image.
# Run this on the Proxmox host (as root). Adjust variables below as needed.

TEMPLATE_ID="${TEMPLATE_ID:-9000}"
TEMPLATE_NAME="${TEMPLATE_NAME:-ubuntu-2204-cloudinit}"
STORAGE="${STORAGE:-local-lvm}"           # Storage for the VM disk (use a directory storage name, e.g., 'vmstore', if you saw the parse error)
SNIPPET_STORAGE="${SNIPPET_STORAGE:-local}" # Storage that holds snippets (leave as 'local' unless you know otherwise)
ISO_STORAGE="${ISO_STORAGE:-local}"       # Storage for ISO/imported image (if using directory storage)
BRIDGE="${BRIDGE:-vmbr0}"
CORES="${CORES:-2}"
MEMORY_MB="${MEMORY_MB:-2048}"
IMAGE_URL="${IMAGE_URL:-https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img}"

WORKDIR="/tmp/proxmox-template-${TEMPLATE_ID}"

echo "Creating workdir ${WORKDIR}..."
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

echo "Downloading cloud image..."
curl -L "${IMAGE_URL}" -o base.img

echo "Creating VM ${TEMPLATE_ID} (${TEMPLATE_NAME})..."
qm create "${TEMPLATE_ID}" --name "${TEMPLATE_NAME}" --memory "${MEMORY_MB}" --cores "${CORES}" --net0 "virtio,bridge=${BRIDGE}"

echo "Importing disk to ${STORAGE}..."
qm importdisk "${TEMPLATE_ID}" base.img "${STORAGE}" --format qcow2

# For directory storage (e.g., NFS/dir), imported disk is usually named vm-<ID>-disk-0.qcow2 under <storage>:<vmid>/...
# For LVM/LVM-thin, qm handles the mapping without a filename suffix.
DISK_REF="${STORAGE}:vm-${TEMPLATE_ID}-disk-0"
if [[ "${STORAGE}" != *"lvm"* ]]; then
  DISK_REF="${STORAGE}:${TEMPLATE_ID}/vm-${TEMPLATE_ID}-disk-0.qcow2"
fi

echo "Attaching disk as scsi0 (${DISK_REF}) and enabling virtio-scsi-pci..."
qm set "${TEMPLATE_ID}" --scsihw virtio-scsi-pci --scsi0 "${DISK_REF}"

echo "Adding cloud-init drive on ${SNIPPET_STORAGE}..."
qm set "${TEMPLATE_ID}" --ide2 "${SNIPPET_STORAGE}:cloudinit"

echo "Setting boot, display, and serial console..."
qm set "${TEMPLATE_ID}" --boot c --bootdisk scsi0 --serial0 socket --vga serial0

echo "Enabling QEMU guest agent..."
qm set "${TEMPLATE_ID}" --agent enabled=1

echo "Converting VM to template..."
qm template "${TEMPLATE_ID}"

echo "Cleaning up..."
rm -rf "${WORKDIR}"

echo "Template ${TEMPLATE_NAME} (${TEMPLATE_ID}) ready. Ensure snippets storage (${SNIPPET_STORAGE}) exists, e.g., /var/lib/vz/snippets for 'local'."
