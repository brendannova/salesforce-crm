# This file converts our configuration data files in version control into a static resource that can be used in Apex tests. 
# It works by:
# - converting ID columns to use DeveloperName__c values
# - updating references to parent relationships to use the parents' DeveloperName__c values
# - dropping parent lookup fields that cannot be processed and are no longer needed after the step above

# To run, open Python virtual environment, run brew install pandas
import pandas as pd

dfEmailConfiguration = pd.read_csv('../../config-data/EmailConfiguration__c.csv', keep_default_na=False)
dfEmailConfiguration['Id'] = dfEmailConfiguration['DeveloperName__c']
dfEmailConfiguration.to_csv('../../force-app/main/default/staticresources/EmailConfiguration.csv', encoding="utf-8", index=False)

dfFactCategory = pd.read_csv('../../config-data/FactCategory__c.csv', keep_default_na=False)
dfFactCategory['Id'] = dfFactCategory['DeveloperName__c']
dfFactCategory.to_csv('../../force-app/main/default/staticresources/FactCategory.csv', encoding="utf-8", index=False)

dfFactCategory = pd.read_csv('../../config-data/Fact__c.csv', keep_default_na=False)
dfFactCategory['Id'] = dfFactCategory['DeveloperName__c']
dfFactCategory['FactCategory__c'] = dfFactCategory['FactCategory__r.DeveloperName__c']
dfFactCategory = dfFactCategory.drop("FactCategory__r.DeveloperName__c", axis='columns')
dfFactCategory.to_csv('../../force-app/main/default/staticresources/Fact.csv', encoding="utf-8", index=False)

dfAdviceType = pd.read_csv('../../config-data/AdviceType__c.csv', keep_default_na=False)
dfAdviceType['Id'] = dfAdviceType['DeveloperName__c']
dfAdviceType.to_csv('../../force-app/main/default/staticresources/AdviceType.csv', encoding="utf-8", index=False)

dfAdviceTypeRecommendation = pd.read_csv('../../config-data/AdviceTypeRecommendation__c.csv', keep_default_na=False)
dfAdviceTypeRecommendation['Id'] = dfAdviceTypeRecommendation['DeveloperName__c']
dfAdviceTypeRecommendation['AdviceType__c'] = dfAdviceTypeRecommendation['AdviceType__r.DeveloperName__c']
dfAdviceTypeRecommendation = dfAdviceTypeRecommendation.drop("AdviceType__r.DeveloperName__c", axis='columns')
dfAdviceTypeRecommendation['RecommendationType__c'] = dfAdviceTypeRecommendation['RecommendationType__r.DeveloperName__c']
dfAdviceTypeRecommendation = dfAdviceTypeRecommendation.drop("RecommendationType__r.DeveloperName__c", axis='columns')
dfAdviceTypeRecommendation.to_csv('../../force-app/main/default/staticresources/AdviceTypeRecommendation.csv', encoding="utf-8", index=False)

dfAdviceTypeStatus = pd.read_csv('../../config-data/AdviceTypeStatus__c.csv', keep_default_na=False)
dfAdviceTypeStatus['Id'] = dfAdviceTypeStatus['DeveloperName__c']
dfAdviceTypeStatus['AdviceType__c'] = dfAdviceTypeStatus['AdviceType__r.DeveloperName__c']
dfAdviceTypeStatus = dfAdviceTypeStatus.drop("AdviceType__r.DeveloperName__c", axis='columns')
dfAdviceTypeStatus.to_csv('../../force-app/main/default/staticresources/AdviceTypeStatus.csv', encoding="utf-8", index=False)

dfRecommendationType = pd.read_csv('../../config-data/RecommendationType__c.csv', keep_default_na=False)
dfRecommendationType['Id'] = dfRecommendationType['DeveloperName__c']
dfRecommendationType.to_csv('../../force-app/main/default/staticresources/RecommendationType.csv', encoding="utf-8", index=False)

dfProvider = pd.read_csv('../../config-data/Public_Provider_Names__c.csv', keep_default_na=False)
dfProvider['Id'] = dfProvider['DeveloperName__c']
dfProvider.to_csv('../../force-app/main/default/staticresources/Public_Provider_Names.csv', encoding="utf-8", index=False)

dfInformationRequestType = pd.read_csv('../../config-data/InformationRequestType__c.csv', keep_default_na=False)
dfInformationRequestType['Id'] = dfInformationRequestType['DeveloperName__c']
dfInformationRequestType.to_csv('../../force-app/main/default/staticresources/InformationRequestType.csv', encoding="utf-8", index=False)

dfAssetType = pd.read_csv('../../config-data/AssetType__c.csv', keep_default_na=False)
dfAssetType['Id'] = dfAssetType['DeveloperName__c']
dfAssetType.to_csv('../../force-app/main/default/staticresources/AssetType.csv', encoding="utf-8", index=False)

dfLiabilityType = pd.read_csv('../../config-data/LiabilityType__c.csv', keep_default_na=False)
dfLiabilityType['Id'] = dfLiabilityType['DeveloperName__c']
dfLiabilityType.to_csv('../../force-app/main/default/staticresources/LiabilityType.csv', encoding="utf-8", index=False)

dfProductType = pd.read_csv('../../config-data/ProductType__c.csv', keep_default_na=False)
dfProductType['Id'] = dfProductType['DeveloperName__c']
dfProductType.to_csv('../../force-app/main/default/staticresources/ProductType.csv', encoding="utf-8", index=False)

dfProduct = pd.read_csv('../../config-data/Product__c.csv', keep_default_na=False)
dfProduct['Id'] = dfProduct['DeveloperName__c']
dfProduct['ProductType__c'] = dfProduct['ProductType__r.DeveloperName__c']
dfProduct = dfProduct.drop("ProductType__r.DeveloperName__c", axis='columns')
dfProduct['Provider__c'] = dfProduct['Provider__r.DeveloperName__c']
dfProduct = dfProduct.drop("Provider__r.DeveloperName__c", axis='columns')
dfProduct.to_csv('../../force-app/main/default/staticresources/Product.csv', encoding="utf-8", index=False)

dfFulfilmentType = pd.read_csv('../../config-data/FulfilmentType__c.csv', keep_default_na=False)
dfFulfilmentType['Id'] = dfFulfilmentType['DeveloperName__c']
dfFulfilmentType['Product__c'] = dfFulfilmentType['Product__r.DeveloperName__c']
dfFulfilmentType = dfFulfilmentType.drop("Product__r.DeveloperName__c", axis='columns')
dfFulfilmentType['RecommendationType__c'] = dfFulfilmentType['RecommendationType__r.DeveloperName__c']
dfFulfilmentType = dfFulfilmentType.drop("RecommendationType__r.DeveloperName__c", axis='columns')
dfFulfilmentType.to_csv('../../force-app/main/default/staticresources/FulfilmentType.csv', encoding="utf-8", index=False)

dfFulfilmentTypeStatus = pd.read_csv('../../config-data/FulfilmentTypeStatus__c.csv', keep_default_na=False)
dfFulfilmentTypeStatus['Id'] = dfFulfilmentTypeStatus['DeveloperName__c']
dfFulfilmentTypeStatus['FulfilmentType__c'] = dfFulfilmentTypeStatus['FulfilmentType__r.DeveloperName__c']
dfFulfilmentTypeStatus = dfFulfilmentTypeStatus.drop("FulfilmentType__r.DeveloperName__c", axis='columns')
dfFulfilmentTypeStatus.to_csv('../../force-app/main/default/staticresources/FulfilmentTypeStatus.csv', encoding="utf-8", index=False)

dfFinancialProductType = pd.read_csv('../../config-data/FinancialProductType__c.csv', keep_default_na=False)
dfFinancialProductType['Id'] = dfFinancialProductType['DeveloperName__c']
dfFinancialProductType['DefaultProvider__c'] = dfFinancialProductType['DefaultProvider__r.DeveloperName__c']
dfFinancialProductType = dfFinancialProductType.drop("DefaultProvider__r.DeveloperName__c", axis='columns')
dfFinancialProductType.to_csv('../../force-app/main/default/staticresources/FinancialProductType.csv', encoding="utf-8", index=False)

dfFeeModel = pd.read_csv('../../config-data/FeeModel__c.csv', keep_default_na=False)
dfFeeModel['Id'] = dfFeeModel['DeveloperName__c']
dfFeeModel['Product__c'] = dfFeeModel['Product__r.DeveloperName__c']
dfFeeModel = dfFeeModel.drop("Product__r.DeveloperName__c", axis='columns')
dfFeeModel['RecommendationType__c'] = dfFeeModel['RecommendationType__r.DeveloperName__c']
dfFeeModel = dfFeeModel.drop("RecommendationType__r.DeveloperName__c", axis='columns')
dfFeeModel['RevenueDueTo__c'] = dfFeeModel['RevenueDueTo__r.DeveloperName__c']
dfFeeModel = dfFeeModel.drop("RevenueDueTo__r.DeveloperName__c", axis='columns')
dfFeeModel.to_csv('../../force-app/main/default/staticresources/FeeModel.csv', encoding="utf-8", index=False)