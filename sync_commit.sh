#!/bin/bash

# Configuration for source Git repository (directory where this script is located)
SOURCE_REPO="$(dirname "$0")"

# Configuration for destination Git repository
# Set the path of the CE repo based on you local setup
DEST_REPO="UPDATE_YOUR_COMMUNITY_REPO_PATH"

# Check if destination repository exists
if [ ! -d "$DEST_REPO" ]; then
    echo "Error: Destination repository does not exist."
    exit 1
fi

# Check if the source directory is a git repository
cd "$SOURCE_REPO"
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Source directory is not a Git repository."
    exit 1
fi

# Specify the branch where the commit exists
COMMIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git checkout $COMMIT_BRANCH
if [ $? -ne 0 ]; then
    echo "Error: Failed to checkout the branch with the commit."
    exit 1
fi

# Accept commit ID as the first input
COMMIT_ID=$1

# Accept optional branch name as the second input, default to COMMIT_ID-branch if not provided
BRANCH_NAME=${2:-$COMMIT_ID-branch}

if [ -z "$COMMIT_ID" ]; then
    echo "Error: No commit ID provided."
    exit 1
fi

# Generating the patch in the source repository
cd "$SOURCE_REPO"
if ! git log -1 $COMMIT_ID > /tmp/commit_message.txt; then
    echo "Error: Commit ID $COMMIT_ID not found in source repository."
    exit 1
fi

git format-patch -1 $COMMIT_ID --stdout > /tmp/$COMMIT_ID.patch
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate patch for commit $COMMIT_ID."
    exit 1
fi

# Updating the main branch and creating a new branch in the destination repo
cd "$DEST_REPO"
git checkout main
if [ $? -ne 0 ]; then
    echo "Error: Main branch does not exist in the destination repository."
    exit 1
fi

git pull
if [ $? -ne 0 ]; then
    echo "Error: Failed to pull latest updates from the main branch."
    exit 1
fi

git checkout -b "$BRANCH_NAME"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create a new branch in the destination repository."
    exit 1
fi

# Applying the patch to the destination repository
cd "$DEST_REPO"
git apply /tmp/$COMMIT_ID.patch
if [ $? -ne 0 ]; then
    echo "Error: Failed to apply the patch to the destination repository."
    exit 1
fi

# Add all changes to the staging area
git add .
if [ $? -ne 0 ]; then
    echo "Error: Failed to add changes to the staging area."
    exit 1
fi

# Committing the changes in the destination repository
git commit -F /tmp/commit_message.txt
if [ $? -ne 0 ]; then
    echo "Error: Failed to commit the patch in the destination repository."
    exit 1
fi

echo "Patch applied successfully and new branch $BRANCH_NAME created in destination repository."

# Cleaning up temporary files
rm /tmp/$COMMIT_ID.patch
rm /tmp/commit_message.txt
