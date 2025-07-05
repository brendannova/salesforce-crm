#!/bin/bash

# This script simplifies the process of raising a PR at the beginning of the Nova Salesforce CI/CD pipeline
# The script can be run with the sandbox alias as an initial argument
# If this is not done, it will be captured as an input before proceeding

# Determine the source branch name and description
echo "Provide the source branch name"
read source_branch_name

echo "Provide a description"
read pr_description

# Define the start of the pipeline
pipeline_start=dev 

# Run the git command to create the PR
gh pr create --base $pipeline_start --head $source_branch_name --title "$source_branch_name" --body "$pr_description"