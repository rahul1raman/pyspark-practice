## Pyspark Practice

Clone the repo and then follow the commands below

## Spark setup (k8s and docker required)
```bash
./dev prepare
./dev install
```

## To reset local minio
```bash
./dev reset-minio
```

## Misc
kubectl get pods
kubectl logs <pod-name>

## Install dependencies if using on local
```bash
pip install -r src/requirements.txt
```

## Web URLs
- Minio: http://localhost:30002
- Spark Master: http://localhost:30080/
- Jupyter Notebook: http://localhost:30888