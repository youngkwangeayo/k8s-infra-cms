

# 클러스터 기본 세팅

```bash
kubectl config get-clusters
# 클러스터 없으면 추가.
aws eks update-kubeconfig --region <리전이름> --name <클러스터이름>

# 작업할클러스터 선택
kubectl config use-context <클러스터arn>
# 현재 클러스터 재확인.
kubectl config current-context

```

# 내부접속
```bash
# pod 접속
kubectl exec -it <podName> -n <nameSpace> -- /bin/bash

#노드진입
kubectl debug node/<nodeName> -it --image=busybox

```


# 베포 
```bash
# 일반 파일
kubectl apply -f <dir>/<yamlfile>
kubectl apply -f <dir>/

# 재베포
kubectl apply -f <yamlFile> --force
kubectl rollout restart deployment/<podName> -n <nameSpace>
```


# 로그
```bash
# 로깅확인
kubectl logs -n logging deployments/logging-backend # -f # 실시간 와치 옵션

# 로그파일 확인
kubectl exec -it -n logging <로깅파드네임> -- /bin/sh
# 로그쌓이는거 확인
ls /var/log/logging_backend/
cat /var/log/logging_backend/aiagent/stdout-20250828.log #파일이름 확인하기
```



# 로드밸런서 프로비저닝 확인
```bash
# Deployment 상태 확인
kubectl get deployment -n kube-system aws-load-balancer-controller
# Pod 상태 확인
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
# 상세 정보 확인
kubectl describe deployment aws-load-balancer-controller -n kube-system  # --tail=10  #   | tail -n 10 # | head -n 10
# 로그 확인
kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller # --tail=10  # | tail -n 10 # | head -n 10
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=20 2>/dev/null

# ServiceAccount 확인
kubectl get serviceaccount aws-load-balancer-controller -n kube-system

# ServiceAccount 상세 정보 (IAM Role 연결 확인)
kubectl describe serviceaccount aws-load-balancer-controller -n kube-system

# 베포안되어있을시
kubectl describe ingress -n <nameSpace> <ingressName>
```