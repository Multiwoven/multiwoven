#!/bin/bash
set -e  # Exit on any error

# Define the path to the pre-extracted directory
EXTRACTED_DIR="/rails/vendor/unixODBC-2.3.11"

echo "Navigating to the unixODBC directory..."
cd $EXTRACTED_DIR

echo "Starting the configure process..."
./configure

echo "Running make..."
make

echo "Running make install..."
make install

echo "unixODBC installation completed successfully."
