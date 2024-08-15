#!/bin/sh

MACHINE=`uname -m`

case "$MACHINE" in
  "x86_64" ) ARC=amd64 ;;
  "aarch64" ) ARC=aarch64 ;;
esac

wget -O duckdb_cli.zip "https://github.com/duckdb/duckdb/releases/download/v1.0.0/duckdb_cli-linux-$ARC.zip"