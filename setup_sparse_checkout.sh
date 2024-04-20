#!/bin/bash
# Enable sparse checkout
git config core.sparseCheckout true

# Define sparse checkout rules
echo "/*" > .git/info/sparse-checkout
echo "!README.md" >> .git/info/sparse-checkout

# Add upstream repository for synchronization
git remote add upstream git@github.com:Multiwoven/multiwoven.git

# Fetch updates from upstream without merging
git fetch upstream

# Pull the current branch from origin to apply sparse checkout
git pull origin main

# Optionally, merge changes from upstream if needed
# git merge upstream/main
