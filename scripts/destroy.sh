#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
AWS_REGION="${AWS_REGION:-eu-west-3}"

export ENV
export AWS_REGION

if [[ "${ENV}" == "prod" ]]; then
  read -r -p "You are about to destroy PROD infrastructure. Type 'yes' to continue: " CONFIRM
  if [[ "${CONFIRM}" != "yes" ]]; then
    echo "Abort."
    exit 1
  fi
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="${ROOT_DIR}/infra"
FORCE_CLEANUP="${FORCE_CLEANUP:-false}"

cd "${INFRA_DIR}"
terraform init

CLUSTER_NAME="$(terraform output -raw eks_cluster_name 2>/dev/null || true)"

# Guard against terraform warnings/noise being captured as a "name".
if [[ -n "${CLUSTER_NAME}" ]] && [[ "${#CLUSTER_NAME}" -le 100 ]] && [[ "${CLUSTER_NAME}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}" || true
else
  echo "Skipping kubeconfig update (no valid EKS cluster name in terraform output)."
fi

helm uninstall grandnode2 -n grandnode2 || true
helm uninstall mongodb -n grandnode2 || true
helm uninstall aws-load-balancer-controller -n kube-system || true
kubectl delete ingress --all -n grandnode2 --ignore-not-found=true || true
kubectl delete svc --all -n grandnode2 --ignore-not-found=true || true
kubectl delete namespace grandnode2 --ignore-not-found=true || true
kubectl wait --for=delete namespace/grandnode2 --timeout=180s || true

# Optional aggressive cleanup for stuck VPC dependencies (ALBs, NAT, IGW, ENIs).
if [[ "${FORCE_CLEANUP}" == "true" ]]; then
  VPC_ID="$(terraform output -raw vpc_id 2>/dev/null || true)"
  if [[ -n "${VPC_ID}" ]]; then
    echo "FORCE_CLEANUP=true: cleaning AWS resources in VPC ${VPC_ID}"

    LBS="$(aws elbv2 describe-load-balancers --region "${AWS_REGION}" \
      --query "LoadBalancers[?VpcId=='${VPC_ID}'].LoadBalancerArn" --output text 2>/dev/null || true)"
    if [[ -n "${LBS}" ]]; then
      for arn in ${LBS}; do
        aws elbv2 delete-load-balancer --region "${AWS_REGION}" --load-balancer-arn "${arn}" || true
      done
      aws elbv2 wait load-balancers-deleted --region "${AWS_REGION}" --load-balancer-arns ${LBS} || true
    fi

    NATS="$(aws ec2 describe-nat-gateways --region "${AWS_REGION}" \
      --filter Name=vpc-id,Values="${VPC_ID}" \
      --query "NatGateways[*].NatGatewayId" --output text 2>/dev/null || true)"
    if [[ -n "${NATS}" ]]; then
      for ngw in ${NATS}; do
        aws ec2 delete-nat-gateway --region "${AWS_REGION}" --nat-gateway-id "${ngw}" || true
      done
      aws ec2 wait nat-gateway-deleted --region "${AWS_REGION}" --nat-gateway-ids ${NATS} || true
    fi

    VPC_EPS="$(aws ec2 describe-vpc-endpoints --region "${AWS_REGION}" \
      --filters Name=vpc-id,Values="${VPC_ID}" \
      --query "VpcEndpoints[*].VpcEndpointId" --output text 2>/dev/null || true)"
    if [[ -n "${VPC_EPS}" ]]; then
      aws ec2 delete-vpc-endpoints --region "${AWS_REGION}" --vpc-endpoint-ids ${VPC_EPS} || true
    fi

    IGWS="$(aws ec2 describe-internet-gateways --region "${AWS_REGION}" \
      --filters Name=attachment.vpc-id,Values="${VPC_ID}" \
      --query "InternetGateways[*].InternetGatewayId" --output text 2>/dev/null || true)"
    if [[ -n "${IGWS}" ]]; then
      for igw in ${IGWS}; do
        aws ec2 detach-internet-gateway --region "${AWS_REGION}" --internet-gateway-id "${igw}" --vpc-id "${VPC_ID}" || true
        aws ec2 delete-internet-gateway --region "${AWS_REGION}" --internet-gateway-id "${igw}" || true
      done
    fi

    ENIS="$(aws ec2 describe-network-interfaces --region "${AWS_REGION}" \
      --filters Name=vpc-id,Values="${VPC_ID}" Name=status,Values=available \
      --query "NetworkInterfaces[*].NetworkInterfaceId" --output text 2>/dev/null || true)"
    if [[ -n "${ENIS}" ]]; then
      for eni in ${ENIS}; do
        aws ec2 delete-network-interface --region "${AWS_REGION}" --network-interface-id "${eni}" || true
      done
    fi

    SGS="$(aws ec2 describe-security-groups --region "${AWS_REGION}" \
      --filters Name=vpc-id,Values="${VPC_ID}" \
      --query "SecurityGroups[?GroupName!='default'].GroupId" --output text 2>/dev/null || true)"
    if [[ -n "${SGS}" ]]; then
      for sg in ${SGS}; do
        aws ec2 delete-security-group --region "${AWS_REGION}" --group-id "${sg}" || true
      done
    fi
  else
    echo "FORCE_CLEANUP=true but no VPC ID found in terraform output."
  fi
fi

# TODO: Optionally uninstall AWS Load Balancer Controller if this cluster is being fully decommissioned.
# helm uninstall aws-load-balancer-controller -n kube-system || true

terraform destroy -auto-approve \
  -var="env=${ENV}" \
  -var="aws_region=${AWS_REGION}"

echo "Destroy complete for ENV=${ENV} in AWS_REGION=${AWS_REGION}."
