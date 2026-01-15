

# helm 용 베포.

```bash
kubectl apply -f helm-charts/namespace-dev.yaml

helm upgrade --install infra helm-charts/infra/ \
     -n dev-cms \
     -f helm-charts/infra/values.yaml \
     -f helm-charts/infra/values-dev.yaml


helm upgrade --install cms helm-charts/cms/ \
     -n dev-cms \
     -f helm-charts/cms/values.yaml \
     -f helm-charts/cms/values-dev.yaml 
helm upgrade --install cms-cron helm-charts/cms-cron/ \
     -n dev-cms \
     -f helm-charts/cms-cron/values.yaml \
     -f helm-charts/cms-cron/values-dev.yaml 


helm upgrade --install logging-backend helm-charts/logging/logging-backend/ \
     -n logging \
     -f helm-charts/logging/logging-backend/values.yaml \
     -f helm-charts/logging/logging-backend/values-dev.yaml 


helm repo add fluent https://fluent.github.io/helm-charts
helm upgrade --install fluent-bit fluent/fluent-bit \
  --version 0.52.0 \
  -n logging \
  -f helm-charts/logging/fluentbit/values.yaml \
  -f helm-charts/logging/fluentbit/values-dev.yaml

kubectl rollout restart deployment -n kube-system aws-load-balancer-controller 
```
