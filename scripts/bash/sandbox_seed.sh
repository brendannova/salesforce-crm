#!/bin/bash

# Define the prod alias that will be used in knowing the source org
prod_alias=prod 

# Get to the config data directory where the export.json file is
cd ~
cd VSC/Pipeline/configuration-data/salesforce-crm/config-data

# Define the source and target orgs, source being locked to prod 
# at this stage and target being the initial argument. 
source_org=$prod_alias
target_org=$1

echo "Launching SFDMU config data run from $source_org => $target_org"
sf sfdmu run -s $source_org -u $target_org

# To consider: add validation to prevent prod being the target