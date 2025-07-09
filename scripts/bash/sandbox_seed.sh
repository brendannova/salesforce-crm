#!/bin/bash

# This script simplifies the process seeding config data from production only to a sandbox
# The script can be run with the sandbox alias as an initial argument
# If this is not done, it will be captured as an input before proceeding

# Determine the target org
if [ -z $1 ]; then
    echo "Provide target org alias"
    read target_org
else
    target_org=$1
fi

# To consider: add validation to prevent prod being the target

# Define the prod alias that will be used in knowing the source org
# Written this way to support other sources in the future
prod_alias=prod 
source_org=$prod_alias

# Get to the config data directory where the export.json file is
cd ~
cd VSC/Pipeline/configuration-data/salesforce-crm/config-data

echo -e "\nLaunching SFDMU to move config data run from $source_org → $target_org\n"
sf sfdmu run -s $source_org -u $target_org