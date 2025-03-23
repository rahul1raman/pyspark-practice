#!/bin/bash

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Download and extract files
curl -L -o donation.zip https://bit.ly/1Aoywaq
unzip donation.zip
unzip 'block_*.zip'

# Setup kubectl port-forward
kubectl port-forward svc/minio-service 9000:9000 &
PORT_FORWARD_PID=$!
sleep 5

# Configure MinIO client
mc alias set local http://localhost:9000 fakesecret fakesecret

# Upload only CSV files
echo "Uploading CSV files to MinIO bucket..."
find . -name "*.csv" -exec mc cp {} local/local-datalake/raw/ \;

# Clean up
kill $PORT_FORWARD_PID
cd ..
rm -rf $TEMP_DIR

echo "CSV files uploaded successfully."