## Install locally and other commands

kubectl apply -f deployments/spark-deployment.yaml
kubectl apply -f deployments/spark-service.yaml

kubectl get pods
kubectl logs <pod-name>

## Port forward to see spark UI
kubectl port-forward spark-standalone-656544f5b8-zvz6v 8080:8080
