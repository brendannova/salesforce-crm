# This file converts our configuration data files in version control into a static resource that can be used in Apex tests. 
# It works by:
# - converting ID columns to use DeveloperName__c values
# - updating references to parent relationships to use the parents' DeveloperName__c values
# - dropping parent lookup fields that cannot be processed and are no longer needed after the step above
import pandas as pd

dfAdviceType = pd.read_csv('../../config-data/AdviceType__c.csv', keep_default_na=False)
dfAdviceType['Id'] = dfAdviceType['DeveloperName__c']
dfAdviceType.to_csv('../../force-app/main/default/staticresources/AdviceType.csv', encoding="utf-8", index=False)

dfAdviceTypeStatus = pd.read_csv('../../config-data/AdviceTypeStatus__c.csv', keep_default_na=False)
dfAdviceTypeStatus['Id'] = dfAdviceTypeStatus['DeveloperName__c']
dfAdviceTypeStatus['AdviceType__c'] = dfAdviceTypeStatus['AdviceType__r.DeveloperName__c']
dfAdviceTypeStatus = dfAdviceTypeStatus.drop("AdviceType__r.DeveloperName__c", axis='columns')
dfAdviceTypeStatus.to_csv('../../force-app/main/default/staticresources/AdviceTypeStatus.csv', encoding="utf-8", index=False)