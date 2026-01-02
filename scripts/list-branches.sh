#!/bin/bash

# Script to list available branches for Jenkins build
# This can be used to dynamically populate the BRANCH parameter in Jenkins

echo "Available branches in AL-chan repository:"
echo "=========================================="

# List all remote branches
git branch -r | grep -v '\->' | sed 's/origin\///' | while read branch; do
    echo "  - ${branch}"
done

echo "=========================================="
echo ""
echo "To update the Jenkinsfile with these branches:"
echo "1. Edit Jenkinsfile"
echo "2. Update the 'BRANCH' parameter choices"
echo "3. Commit and push changes"
