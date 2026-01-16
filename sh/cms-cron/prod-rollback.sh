#!/bin/bash
# =============================================================================
# !!!주의 자동화 생성이므로 절대 건들지마시오!!!
# prod-rollback.sh - Prod 환경 Helm 롤백 스크립트
# 생성일: 2026-01-16 09:09:13
# 롤백 대상 리비전: 3
# =============================================================================

set -e

APP_NAME="cms-cron"
ENV="dev"
NAMESPACE="${ENV}-cms"
ROLLBACK_REVISION="3"

echo "=========================================="
echo " Prod Rollback Script"
echo " App: ${APP_NAME}"
echo " Namespace: ${NAMESPACE}"
echo " Rollback to revision: ${ROLLBACK_REVISION}"
echo "=========================================="

# -----------------------------------------------------------------------------
# 1. 필수 도구 설치 확인
# -----------------------------------------------------------------------------
echo "[1/3] Checking required tools..."

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
echo "[2/3] Connecting to EKS cluster..."

EKS_CLUSTER_NAME="eks-dev-cms"
AWS_REGION="ap-northeast-2"

aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"
echo "  - Connected to cluster: $EKS_CLUSTER_NAME"
echo ""

# 현재 히스토리 출력 (참고용)
echo "Current release history:"
helm history "$APP_NAME" -n "$NAMESPACE" --max 5
echo ""

# 리비전 확인
if [ "$ROLLBACK_REVISION" == "0" ]; then
    echo "ERROR: No previous revision available. This is the first deployment."
    exit 1
fi

read -p "Rolling back to revision ${ROLLBACK_REVISION}. Proceed? (y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Rollback cancelled."
    exit 0
fi

# -----------------------------------------------------------------------------
# 3. Helm 롤백 실행
# -----------------------------------------------------------------------------
echo "[3/3] Rolling back to revision ${ROLLBACK_REVISION}..."

helm rollback "$APP_NAME" "$ROLLBACK_REVISION" -n "$NAMESPACE"

echo ""
echo "Waiting for rollout to complete..."
kubectl rollout status deployment/"$APP_NAME" -n "$NAMESPACE" --timeout=300s

echo ""
echo "=========================================="
echo " Rollback completed successfully!"
echo " Rolled back to revision: ${ROLLBACK_REVISION}"
echo "=========================================="
