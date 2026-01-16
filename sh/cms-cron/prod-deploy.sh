#!/bin/bash
# =============================================================================
# !!!주의 자동화 생성이므로 절대 건들지마시오!!!
# prod-deploy.sh - Prod 환경 Helm 배포 스크립트
# 생성일: 2026-01-16 09:09:13
# =============================================================================

set -e

APP_NAME="cms-cron"
IMAGE_TAG="0.0.2.k8s"
ENV="dev"
NAMESPACE="${ENV}-cms"

echo "=========================================="
echo " Prod Deploy Script"
echo " App: ${APP_NAME}"
echo " Tag: ${IMAGE_TAG}"
echo " Namespace: ${NAMESPACE}"
echo "=========================================="

# -----------------------------------------------------------------------------
# 1. 필수 도구 설치 확인
# -----------------------------------------------------------------------------
echo "[1/4] Checking required tools..."

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "ERROR: $1 is not installed. Please install $1 first."
        exit 1
    fi
    echo "  - $1: OK"
}

check_command aws
check_command kubectl
check_command helm

echo ""

# -----------------------------------------------------------------------------
# 2. AWS EKS 클러스터 연결
# -----------------------------------------------------------------------------
echo "[2/4] Connecting to EKS cluster..."

EKS_CLUSTER_NAME="eks-dev-cms"
AWS_REGION="ap-northeast-2"

aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"
echo "  - Connected to cluster: $EKS_CLUSTER_NAME"
echo ""

# -----------------------------------------------------------------------------
# 3. Helm 배포 실행
# -----------------------------------------------------------------------------
echo "[3/4] Deploying with Helm..."

CHART_PATH="helm-charts/${APP_NAME}"

if [ ! -d "$CHART_PATH" ]; then
    echo "ERROR: Helm chart not found at ${CHART_PATH}"
    exit 1
fi

helm upgrade --install "$APP_NAME" "$CHART_PATH/" \
    -n "$NAMESPACE" \
    -f "${CHART_PATH}/values.yaml" \
    -f "${CHART_PATH}/values-${ENV}.yaml" \
    --set image.tag="$IMAGE_TAG"

echo ""

# -----------------------------------------------------------------------------
# 4. 배포 완료 대기
# -----------------------------------------------------------------------------
echo "[4/4] Waiting for rollout to complete..."

kubectl rollout status deployment/"$APP_NAME" -n "$NAMESPACE" --timeout=300s

echo ""
echo "=========================================="
echo " Deployment completed successfully!"
echo "=========================================="
