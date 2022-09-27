@description('Azure region to which the resources will be deployed. (Defaults to East US)')
param location string = resourceGroup().location

@description('Name for resources to be deployed. (Defaults to deterministic uniqueString value)')
param name string = 'b${uniqueString(resourceGroup().id)}'

@description('Azure API Management publisher emai.')
param publisherEmail string

@description('Azure API Management publisher name.')
param publisherName string

@description('Storage account SKU name.')
param storageSku string = 'Standard_LRS'

@description('Azure Active Directory Application (Client) ID for the App Registration representing the Function App')
param azureAdClientId string

@description('Azure Active Directory Application Secret for the App Registration representing the Function App')
@secure()
param azureAdClientSecret string

param utcValue string = utcNow()

module appInsights 'app-insights.bicep' = {
  name: 'appInsights-${utcValue}'
  params: {
    location: location
    name: name
  }
}

module functionApp 'function-app.bicep' = {
  name: 'functionApp-${utcValue}'
  params: {
    location: location
    name: name
    appInsightsName: appInsights.outputs.appInsightsName
    azureAdClientId: azureAdClientId
    azureAdClientSecret: azureAdClientSecret
    storageSku: storageSku 
  }
}

module apiManagement 'api-management.bicep' = {
  name: 'apiManagement-${utcValue}'
  params: {
    location: location
    name: name
    functionAppName: functionApp.outputs.functionAppName
    httpTriggeredFunctionName: functionApp.outputs.httpTriggeredFunctionName
    publisherEmail: publisherEmail
    publisherName: publisherName
    azureAdClientId: azureAdClientId
  }
}

output redirectUri string = functionApp.outputs.azureAdFunctionAppRedirectUri
output apiUri string = apiManagement.outputs.apiManagementOperationUri
