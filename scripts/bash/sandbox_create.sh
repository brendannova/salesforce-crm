#!/bin/bash

# Define the prod alias that will be used in knowing the source org
prod_alias=prod 

# Capture sandbox name from user, which will also be the alias
echo -e "\n Enter sandbox name (max. 10 char)"
read sandbox_name

# Run sandbox creation asynchronously
sf org create sandbox --name $sandbox_name --license-type Developer --alias $sandbox_name --target-org $prod_alias --set-default --async

# Confirmation
echo -e "\n Sandbox $sandbox_name creation started. "

# To do: Conditionally trigger sandbox seeding
# echo -e "\n Seed with config data? [y/n]"
# read seed_config_data

#if [ "$seed_config_data" = "y" ]; then
  # bash sandbox_seed.sh $sandbox_name | at now + 1 hour
  # echo -e "\n Sandbox config data seeding job queued"
# fi