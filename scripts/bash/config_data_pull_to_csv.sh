#!/bin/bash

# This script simplifies the process seeding config data from production only to a sandbox
# The script can be run with the sandbox alias as an initial argument
# If this is not done, it will be captured as an input before proceeding

# Determine the target org
if [ -z $1 ]; then
    echo "Provide source org alias"
    read source_org
else
    source_org=$1
fi

# To consider: add validation to prevent prod being the target

# Define the prod alias that will be used in knowing the source org
# Written this way to support other sources in the future
csv_target_alias=csvfile 
target_org=$csv_target_alias

# Get to the config data directory where the export.json file is
cd ../../config-data

echo -e "\nLaunching SFDMU to pull CSV files of config data from $source_org\n"
sf sfdmu run -s $source_org -u $target_org