#!/bin/env bash

kind create cluster --name test --config cluster.yaml

#####################################

# helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
# helm repo add crossplane-stable https://charts.crossplane.io/stable
# helm repo add gitea https://dl.gitea.com/charts
# helm repo add argo https://argoproj.github.io/argo-helm
# helm repo update

helm install my-headlamp headlamp/headlamp \
  --version 0.42.0 \
  --namespace kube-system \
  --set config.baseURL="/headlamp"

kubectl wait --timeout=5m \
  --namespace kube-system \
  deployment my-headlamp \
  --for=condition=Available

######################################

helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.8.1 \
  --namespace envoy-gateway-system \
  --create-namespace

kubectl wait --timeout=5m \
  -n envoy-gateway-system \
  deployment/envoy-gateway \
  --for=condition=Available

kubectl get all -n envoy-gateway-system

################################################

helm install crossplane \
  --version 2.3.1 \
  --namespace crossplane-system \
  --create-namespace crossplane-stable/crossplane

################################################

kubectl apply -f gateway.yaml

kubectl wait deployment \
  -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-name=eg \
  --for=condition=Available \
  --timeout=120s

################################################

helm install gitea oci://docker.gitea.com/charts/gitea \
  --version 12.6.0 \
  --set gitea.admin.username=mantasgudynas \
  --set gitea.admin.password=gitea \
  --set gitea.config.server.ROOT_URL=http://localhost/gitea/

################################################

ARGOCD_PASS=$(htpasswd -nbBC 10 "" argocd | tr -d ':\n' | sed 's/$2y/$2a/')
helm install argocd argo/argo-cd \
  --version 9.5.21 \
  --set configs.params."server\.insecure"=true \
  --set configs.params."server\.basehref"=/argocd \
  --set configs.params."server\.rootpath"=/argocd \
  --set configs.secret.argocdServerAdminPassword="${ARGOCD_PASS}"

################################################

helm install prometheus oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
  --set grafana.adminPassword='grafana' \
  --set grafana."grafana\.ini".server.domain=localhost \
  --set grafana."grafana\.ini".server.root_url='http://localhost/grafana' \
  --set grafana."grafana\.ini".server.serve_from_sub_path=true

################################################

echo
echo "http://localhost/headlamp/"
echo
kubectl create token my-headlamp --namespace kube-system --duration=128h
echo
