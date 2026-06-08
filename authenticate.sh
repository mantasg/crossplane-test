#!/bin/env bash

set -e

if [ -z "$AWS_ACCESS_KEY_ID" -o -z "$AWS_SECRET_ACCESS_KEY" -o -z "$AWS_SESSION_TOKEN" ]; then
  echo "AWS auth env vars not present"
  exit 1
fi

echo "[default]" > aws-credentials.ini
echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> aws-credentials.ini
echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> aws-credentials.ini
echo "aws_session_token = $AWS_SESSION_TOKEN" >> aws-credentials.ini

kubectl delete secret generic aws-secret --namespace=crossplane-system --ignore-not-found
kubectl create secret generic aws-secret --namespace=crossplane-system --from-file=creds=./aws-credentials.ini

rm aws-credentials.ini