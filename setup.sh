#!/bin/env bash

kind create cluster --name test --config cluster.yaml

#####################################

# helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
# helm repo add crossplane-stable https://charts.crossplane.io/stable
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

echo
echo "http://localhost/headlamp/"
echo
kubectl create token my-headlamp --namespace kube-system --duration=128h
echo
