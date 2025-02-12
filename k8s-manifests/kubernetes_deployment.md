1) Install kuberenetes on all hosts
2) Make sure joining from workers works

kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
kubectl apply -f django-deployment.yaml
kubectl apply -f django-service.yaml



## Steps forward:

### Kubernetes auto-deployed on 2 hosts - Amazon Linux 2 - containerd -> DONE
### Kubernetes auto-deployed on 3 hosts - Amazon Linux 2 - containerd ->
### Kubernetes auto-deployed on 2 hosts - Amazon Linux 2 - Docker ->
### Kubernetes auto-deployed on 3 hosts - Amazon Linux 2 - Docker -> 