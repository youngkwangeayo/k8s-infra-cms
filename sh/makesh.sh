#!/bin/bash
# =============================================================================
# makesh.sh - Prod 배포/롤백 스크립트 생성기
# 사용법: ./makesh.sh <ENV> <APP_NAME> <IMAGE_TAG> <CURRENT_REVISION>
# =============================================================================

set -e

# 매개변수 검증
if [ $# -lt 4 ]; then
    echo "Usage: $0 <ENV> <APP_NAME> <IMAGE_TAG> <CURRENT_REVISION>"
    echo "Example: $0 prod cms v1.0.0 5"
    exit 1
fi

ENV=$1
APP_NAME=$2
IMAGE_TAG=$3
CURRENT_REVISION=$4

SCRIPT_DIR="sh/${APP_NAME}"

# 디렉토리 생성
mkdir -p "$SCRIPT_DIR"

echo "Generating deploy scripts for ${APP_NAME} with tag ${IMAGE_TAG} in ${ENV} environment..."

# =============================================================================
# prod-deploy.sh 생성
# =============================================================================
cat > "${SCRIPT_DIR}/prod-deploy.sh" << 'DEPLOY_EOF'
#!/bin/bash
# =============================================================================
# !!!주의 자동화 생성이므로 절대 건들지마시오!!!
# prod-deploy.sh - Prod 환경 Helm 배포 스크립트
# 생성일: GENERATED_DATE
# =============================================================================

set -e

APP_NAME="APP_NAME_PLACEHOLDER"
IMAGE_TAG="IMAGE_TAG_PLACEHOLDER"
ENV="ENV_PLACEHOLDER"
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

EKS_CLUSTER_NAME="EKS_CLUSTER_PLACEHOLDER"
AWS_REGION="AWS_REGION_PLACEHOLDER"

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
DEPLOY_EOF

# 플레이스홀더 치환
sed -i.bak "s/APP_NAME_PLACEHOLDER/${APP_NAME}/g" "${SCRIPT_DIR}/prod-deploy.sh"
sed -i.bak "s/IMAGE_TAG_PLACEHOLDER/${IMAGE_TAG}/g" "${SCRIPT_DIR}/prod-deploy.sh"
sed -i.bak "s/ENV_PLACEHOLDER/${ENV}/g" "${SCRIPT_DIR}/prod-deploy.sh"
sed -i.bak "s/EKS_CLUSTER_PLACEHOLDER/${EKS_PROD_CLUSTER_NAME}/g" "${SCRIPT_DIR}/prod-deploy.sh"
sed -i.bak "s/AWS_REGION_PLACEHOLDER/${AWS_DEFAULT_REGION}/g" "${SCRIPT_DIR}/prod-deploy.sh"
sed -i.bak "s/GENERATED_DATE/$(date '+%Y-%m-%d %H:%M:%S')/g" "${SCRIPT_DIR}/prod-deploy.sh"
rm -f "${SCRIPT_DIR}/prod-deploy.sh.bak"

chmod +x "${SCRIPT_DIR}/prod-deploy.sh"
echo "Created: ${SCRIPT_DIR}/prod-deploy.sh"

# =============================================================================
# prod-rollback.sh 생성
# =============================================================================
cat > "${SCRIPT_DIR}/prod-rollback.sh" << 'ROLLBACK_EOF'
#!/bin/bash
# =============================================================================
# !!!주의 자동화 생성이므로 절대 건들지마시오!!!
# prod-rollback.sh - Prod 환경 Helm 롤백 스크립트
# 생성일: GENERATED_DATE
# 롤백 대상 리비전: ROLLBACK_REVISION_PLACEHOLDER
# =============================================================================

set -e

APP_NAME="APP_NAME_PLACEHOLDER"
ENV="ENV_PLACEHOLDER"
NAMESPACE="${ENV}-cms"
ROLLBACK_REVISION="ROLLBACK_REVISION_PLACEHOLDER"

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

EKS_CLUSTER_NAME="EKS_CLUSTER_PLACEHOLDER"
AWS_REGION="AWS_REGION_PLACEHOLDER"

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
ROLLBACK_EOF

# 플레이스홀더 치환
sed -i.bak "s/APP_NAME_PLACEHOLDER/${APP_NAME}/g" "${SCRIPT_DIR}/prod-rollback.sh"
sed -i.bak "s/ENV_PLACEHOLDER/${ENV}/g" "${SCRIPT_DIR}/prod-rollback.sh"
sed -i.bak "s/EKS_CLUSTER_PLACEHOLDER/${EKS_PROD_CLUSTER_NAME}/g" "${SCRIPT_DIR}/prod-rollback.sh"
sed -i.bak "s/AWS_REGION_PLACEHOLDER/${AWS_DEFAULT_REGION}/g" "${SCRIPT_DIR}/prod-rollback.sh"
sed -i.bak "s/ROLLBACK_REVISION_PLACEHOLDER/${CURRENT_REVISION}/g" "${SCRIPT_DIR}/prod-rollback.sh"
sed -i.bak "s/GENERATED_DATE/$(date '+%Y-%m-%d %H:%M:%S')/g" "${SCRIPT_DIR}/prod-rollback.sh"
rm -f "${SCRIPT_DIR}/prod-rollback.sh.bak"

chmod +x "${SCRIPT_DIR}/prod-rollback.sh"
echo "Created: ${SCRIPT_DIR}/prod-rollback.sh"

echo ""
echo "=========================================="
echo " Script generation completed!"
echo " Files created:"
echo "   - ${SCRIPT_DIR}/prod-deploy.sh"
echo "   - ${SCRIPT_DIR}/prod-rollback.sh"
echo ""
echo " After git pull, run the deploy script:"
echo "   cd $(pwd)"
echo "   ./${SCRIPT_DIR}/prod-deploy.sh"
echo "=========================================="
