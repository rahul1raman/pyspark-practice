## Pyspark Practice

Clone the repo and then follow the commands below

## Spark setup (k8s required)
```bash
kubectl apply -f deployments/spark-jupyter-standalone.yaml
```

kubectl get pods
kubectl logs <pod-name>

## Install dependencies if using on local
```bash
pip install -r src/requirements.txt
```
##  

## Port forward to see spark UI
```bash
 kubectl port-forward service/spark-jupyter-service 7077:7077 8080:8080 4040:4040 8888:8888
```
Spark UI: localhost:8080
Spark Plan: localhost:4040
Jupyter: localhost:8888