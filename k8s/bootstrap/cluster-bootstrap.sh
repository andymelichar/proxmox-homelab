#!/usr/bin/env bash
set -euo pipefail

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found in PATH. Run this from the jumphost after copying kubeconfig." >&2
  exit 1
fi

echo "Applying ArgoCD core..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Applying root App of Apps..."
kubectl apply -f gitops/argocd/root-app.yaml

echo "Bootstrap triggered. Check ArgoCD UI or 'kubectl get applications -n argocd' for sync status."
