#!/bin/bash
set -e  # Exit on any error

# Define the path to the pre-extracted directory
EXTRACTED_DIR="/rails/vendor/libiodbc-3.52.10"

echo "Navigating to the libiODBC directory..."
cd $EXTRACTED_DIR

autoreconf -f -i

echo "Starting the configure process..."
./configure

echo "Running make..."
make

echo "Running make install..."
make install

echo "libiODBC installation completed successfully."
