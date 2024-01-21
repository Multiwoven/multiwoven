#!/bin/bash

# Define your submodule repositories
MULTIWOVEN_SERVER_REPO="git@github.com:Multiwoven/multiwoven-server.git"
MULTIWOVEN_UI_REPO="git@github.com:Multiwoven/multiwoven-ui.git"
MULTIWOVEN_INTEGRATIONS="git@github.com:Multiwoven/multiwoven-integrations.git"

# Function to add or update a submodule
add_or_update_submodule() {
    local repo_url=$1
    local path=$2

    # Check if the submodule already exists
    if [ -d "$path/.git" ]; then
        echo "Updating submodule $path"
        # Submodule already exists, just update it
        git submodule update --remote $path
    else
        echo "Adding submodule $path"
        # Add the submodule
        git submodule add $repo_url $path
        git submodule init $path
    fi
}

# Add or update submodules
add_or_update_submodule $MULTIWOVEN_SERVER_REPO "multiwoven-server"
add_or_update_submodule $MULTIWOVEN_UI_REPO "multiwoven-ui"
add_or_update_submodule $MULTIWOVEN_INTEGRATIONS "multiwoven-integrations"

# Commit the changes to the monorepo
git add .
git commit -m "Updated submodules"
git push origin main

echo "Monorepo updated successfully!"
