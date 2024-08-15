#!/bin/sh

# Determine the platform architecture
ARCH=$(uname -m)

# Set the URL based on the architecture
if [ "$ARCH" = "aarch64" ]; then
    URL="http://extensions.duckdb.org/v1.0.0/linux_arm64/httpfs.duckdb_extension.gz"
    DIR="/home/rails/.duckdb/extensions/v1.0.0/linux_arm64/"
elif [ "$ARCH" = "x86_64" ]; then
    URL="http://extensions.duckdb.org/v1.0.0/linux_amd64_gcc4/httpfs.duckdb_extension.gz"
    DIR="/home/rails/.duckdb/extensions/v1.0.0/linux_amd64_gcc4/"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Download the appropriate extension
wget -O httpfs.duckdb_extension.gz "$URL"
gunzip httpfs.duckdb_extension.gz
mkdir -p $DIR
mv httpfs.duckdb_extension $DIR