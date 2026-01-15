

# 자동베포 ( DEV )
- 소스코드레포에서 pipe RUN_ ECR 푸쉬
- 소스코드레포에서 PIPE 에서 curl로 비트버킷 HTTP 호출 (바디값으로 태그와 appName 을보냄)
- k8s PIPE RUN 트리거 동작 _ EKS설정추가 후,   helm 베포 <appName> <tag>


# 수동베포 ( PROD )
> --set image.tag=<태그버전>  특정 버전으로 바꾼후 커맨드 실행.
```bash

helm upgrade --install cms helm-charts/cms/ \
    -n dev-cms \
    -f helm-charts/cms/values.yaml \
    -f helm-charts/cms/values-dev.yaml \
    --set image.tag=1.2.10

helm upgrade --install cms-cron helm-charts/cms-cron/ \
    -n dev-cms \
    -f helm-charts/cms-cron/values.yaml \
    -f helm-charts/cms-cron/values-dev.yaml \
    --set image.tag=1.2.10

```