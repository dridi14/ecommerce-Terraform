#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
AWS_REGION="${AWS_REGION:-eu-west-3}"

export ENV
export AWS_REGION

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="${ROOT_DIR}/infra"
BUILD_IMAGE="${BUILD_IMAGE:-false}"
IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-my-ecr-or-dockerhub/grandnode2}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-${ROOT_DIR}/Dockerfile}"
BUILD_CONTEXT="${BUILD_CONTEXT:-${ROOT_DIR}}"
INSTALL_METRICS_SERVER="${INSTALL_METRICS_SERVER:-true}"
METRICS_SERVER_MANIFEST_URL="${METRICS_SERVER_MANIFEST_URL:-https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml}"
AUTO_INSTALL_EBS_CSI="${AUTO_INSTALL_EBS_CSI:-true}"
WAIT_FOR_ALB_WEBHOOK="${WAIT_FOR_ALB_WEBHOOK:-true}"

log() {
  echo "[$(date +'%H:%M:%S')] $*"
}

log "Starting deployment for ENV=${ENV} in AWS_REGION=${AWS_REGION}"

cd "${INFRA_DIR}"
log "Terraform init"
terraform init
log "Terraform apply"
terraform apply -auto-approve \
  -var="env=${ENV}" \
  -var="aws_region=${AWS_REGION}"

CLUSTER_NAME="$(terraform output -raw eks_cluster_name)"
log "Using EKS cluster: ${CLUSTER_NAME}"

log "Updating kubeconfig"
aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}"

if [[ "${AUTO_INSTALL_EBS_CSI}" == "true" ]]; then
  if ! kubectl get csidriver ebs.csi.aws.com >/dev/null 2>&1; then
    log "EBS CSI driver not detected. Installing addon..."
    aws eks create-addon --cluster-name "${CLUSTER_NAME}" --addon-name aws-ebs-csi-driver --region "${AWS_REGION}" || true
  else
    log "EBS CSI driver detected."
  fi
else
  log "AUTO_INSTALL_EBS_CSI=false (skipping EBS CSI addon install)."
fi

if [[ "${INSTALL_METRICS_SERVER}" == "true" ]]; then
  if ! kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
    log "Installing metrics-server"
    kubectl apply -f "${METRICS_SERVER_MANIFEST_URL}"
  else
    log "metrics-server already installed"
  fi
else
  log "INSTALL_METRICS_SERVER=false (skipping metrics-server install)."
fi

if [[ "${BUILD_IMAGE}" == "true" ]]; then
  log "BUILD_IMAGE=true: building and pushing ${IMAGE_REPOSITORY}:${IMAGE_TAG}"

  if [[ "${IMAGE_REPOSITORY}" == *.dkr.ecr.*.amazonaws.com/* ]]; then
    ECR_REGISTRY="$(echo "${IMAGE_REPOSITORY}" | cut -d'/' -f1)"
    aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"
  fi

  docker build -f "${DOCKERFILE_PATH}" -t "${IMAGE_REPOSITORY}:${IMAGE_TAG}" "${BUILD_CONTEXT}"
  docker push "${IMAGE_REPOSITORY}:${IMAGE_TAG}"
fi

if ! helm status aws-load-balancer-controller -n kube-system >/dev/null 2>&1; then
  log "Installing AWS Load Balancer Controller"
  helm repo add eks https://aws.github.io/eks-charts
  helm repo update

  # TODO: Before running in production, create/attach the IAM role for service account (IRSA)
  # and adjust serviceAccount settings below accordingly.
  helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName="${CLUSTER_NAME}" \
    --set serviceAccount.create=true \
    --set serviceAccount.name=aws-load-balancer-controller
fi

if [[ "${WAIT_FOR_ALB_WEBHOOK}" == "true" ]]; then
  log "Waiting for AWS Load Balancer Controller rollout"
  kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=300s || true
  log "Waiting for ALB webhook endpoints"
  for i in {1..30}; do
    if kubectl get endpoints aws-load-balancer-webhook-service -n kube-system >/dev/null 2>&1; then
      EP_COUNT="$(kubectl get endpoints aws-load-balancer-webhook-service -n kube-system -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w | tr -d ' ')"
      if [[ "${EP_COUNT}" != "0" ]]; then
        break
      fi
    fi
    sleep 5
  done
fi

kubectl get namespace grandnode2 >/dev/null 2>&1 || kubectl create namespace grandnode2

ASPNETCORE_ENVIRONMENT="${ASPNETCORE_ENVIRONMENT:-Production}"
MONGODB_ENABLED="${MONGODB_ENABLED:-true}"
MONGODB_USERNAME="${MONGODB_USERNAME:-grandnodeadmin}"
MONGODB_PASSWORD="${MONGODB_PASSWORD:-ChangeMeMongoPass123}"
MONGODB_DATABASE="${MONGODB_DATABASE:-grandnode2}"
MONGODB_PERSISTENCE_ENABLED="${MONGODB_PERSISTENCE_ENABLED:-true}"
MONGODB_PERSISTENCE_SIZE="${MONGODB_PERSISTENCE_SIZE:-50Gi}"
DB_PROVIDER="${DB_PROVIDER:-0}"
INSTALLER_ENABLED="${INSTALLER_ENABLED:-true}"

if [[ "${MONGODB_ENABLED}" == "true" ]]; then
  log "Installing/Upgrading MongoDB"
  helm repo add bitnami https://charts.bitnami.com/bitnami >/dev/null 2>&1 || true
  helm repo update >/dev/null 2>&1

  helm upgrade --install mongodb bitnami/mongodb \
    -n grandnode2 \
    --set architecture=standalone \
    --set auth.enabled=true \
    --set auth.rootPassword="${MONGODB_PASSWORD}" \
    --set auth.usernames[0]="${MONGODB_USERNAME}" \
    --set auth.passwords[0]="${MONGODB_PASSWORD}" \
    --set auth.databases[0]="${MONGODB_DATABASE}" \
    --set persistence.enabled="${MONGODB_PERSISTENCE_ENABLED}" \
    --set persistence.size="${MONGODB_PERSISTENCE_SIZE}"
fi

if [[ -z "${DB_CONNECTION_STRING:-}" ]]; then
  DB_CONNECTION_STRING="mongodb://${MONGODB_USERNAME}:${MONGODB_PASSWORD}@mongodb.grandnode2.svc.cluster.local:27017/${MONGODB_DATABASE}?authSource=${MONGODB_DATABASE}"
fi

log "Installing/Upgrading GRANDNODE2"
helm upgrade --install grandnode2 "${ROOT_DIR}/k8s/grandnode2" \
  -n grandnode2 \
  --set image.repository="${IMAGE_REPOSITORY}" \
  --set image.tag="${IMAGE_TAG}" \
  --set env.ASPNETCORE_ENVIRONMENT="${ASPNETCORE_ENVIRONMENT}" \
  --set env.DB_CONNECTION_STRING="${DB_CONNECTION_STRING}" \
  --set env.CONNECTIONSTRINGS_MONGODB="${DB_CONNECTION_STRING}" \
  --set env.CONNECTIONSTRINGS_PROVIDER="${DB_PROVIDER}" \
  --set env.FEATURE_INSTALLER="${INSTALLER_ENABLED}"

log "Deployment complete."
log "EKS cluster name: ${CLUSTER_NAME}"
log "Reminder: check the ALB DNS name with: kubectl get ingress -n grandnode2"
