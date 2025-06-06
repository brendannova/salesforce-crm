#!/bin/bash

# Capture target org as an input then call other shall script to seed
echo "Provide target org alias"
read target_org

bash sandbox_seed.sh $target_org