#!/bin/bash
# Enable sparse checkout
git config core.sparseCheckout true

# Define sparse checkout rules
echo "/*" > .git/info/sparse-checkout
echo "!README.md" >> .git/info/sparse-checkout

# Pull the current branch to apply sparse checkout
git pull origin main

