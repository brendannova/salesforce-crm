# Configuration Data
Configuration data will be stored in csv files in this directory. The export.json file will specify source data 

You can use the Shell scripts in scripts/bash to support migrating config data to a sandbox or run the commands below when your export.json file is ready. 

cd ~
cd VSC/Pipeline/configuration-data/salesforce-crm/config-data
sf sfdmu run -s prod -u {sandboxName}