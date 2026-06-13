#!/bin/bash

# Ensure mc client is installed
if ! command -v mc &> /dev/null; then
    if [ -f "$HOME/.local/bin/mc" ]; then
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo "MinIO Client (mc) not found in PATH. Attempting to download..."
        mkdir -p "$HOME/.local/bin"
        if curl -L -o "$HOME/.local/bin/mc" https://dl.min.io/client/mc/release/linux-amd64/mc; then
            chmod +x "$HOME/.local/bin/mc"
            export PATH="$HOME/.local/bin:$PATH"
            echo "MinIO Client (mc) installed successfully to $HOME/.local/bin."
        else
            echo "Error: MinIO Client (mc) is required but not installed."
            echo "Please install it manually: https://github.com/minio/mc"
            exit 1
        fi
    fi
fi

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