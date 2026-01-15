


# 모던 얌 매니페스트 베포

```bash
cd manifes-yaml

kubectl apply -f infra/namespace.yaml
kubectl apply -f infra/

kubectl apply -f cms/
kubectl apply -f cms-cron/


kubectl apply -f logging/logging-backend/


cd ../

helm repo add fluent https://fluent.github.io/helm-charts
helm upgrade --install fluent-bit fluent/fluent-bit \
  --version 0.52.0 \
  -n logging \
  -f helm-charts/logging/fluentbit/values.yaml \
  -f helm-charts/logging/fluentbit/values-dev.yaml


kubectl rollout restart deployment -n kube-system aws-load-balancer-controller

```
