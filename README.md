## Pyspark Practice

Clone the repo and then follow the commands below

## Install Minio
https://github.com/minio/mc

## Spark setup (k8s and docker required)
```bash
./dev install
```
 
## To reset local minio
```bash
./dev reset-minio
```

## Download test data
This copies donation data to local-datalake/raw
```bash
./downloadToMinio.sh
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
