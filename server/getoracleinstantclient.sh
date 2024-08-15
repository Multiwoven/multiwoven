#!/bin/sh

MACHINE=`uname -m`

case "$MACHINE" in
  "x86_64" ) ARC=x86_64 ;;
  "aarch64" ) ARC=aarch64 ;;
  * ) echo "Unsupported architecture: $MACHINE" >&2; exit 1 ;;
esac

# Download basic package
if ! wget http://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient/$ARC/getPackage/oracle-instantclient19.10-basic-19.10.0.0.0-1.$ARC.rpm; then
  echo "Failed to download oracle-instantclient19.10-basic.rpm" >&2
  exit 1
fi

# Download devel package (repeat for devel package)
if ! wget http://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient/$ARC/getPackage/oracle-instantclient19.10-devel-19.10.0.0.0-1.$ARC.rpm; then
  echo "Failed to download oracle-instantclient19.10-devel.rpm" >&2
  exit 1
fi

# Install packages
apt-get update -qq && \
    apt-get install -y libaio1 alien && \
    alien -i --scripts oracle-instantclient19.10-basic-19.10.0.0.0-1.$ARC.rpm && \
    alien -i --scripts oracle-instantclient19.10-devel-19.10.0.0.0-1.$ARC.rpm && \
    rm -f oracle-instantclient19.10-basic-19.10.0.0.0-1.$ARC.rpm && \
    rm -f oracle-instantclient19.10-devel-19.10.0.0.0-1.$ARC.rpm