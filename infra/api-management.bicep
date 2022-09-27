param location string
param name string
param functionAppName string
param httpTriggeredFunctionName string
param publisherEmail string
param publisherName string 
param azureAdClientId string

var apiManagementName = '${name}-apim'

resource functionApp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: functionAppName
}

resource apiManagement 'Microsoft.ApiManagement/service@2021-12-01-preview' = {
  name: apiManagementName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

resource apiManagementPolicy 'Microsoft.ApiManagement/service/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: apiManagement
  properties: {
    format: 'xml'
    value: replace(loadTextContent('apim-policy-global.xml'), '{{AAD_CLIENT_ID}}', azureAdClientId)
  }
}

resource apiManagementFunctionAppKey 'Microsoft.ApiManagement/service/namedValues@2021-12-01-preview' = {
  name: '${functionApp.name}-key'
  parent: apiManagement
  properties: {
    displayName: '${functionApp.name}-key'
    secret: true
    value: listkeys('${functionApp.id}/host/default', '2022-03-01').functionKeys.default
  }
}

resource apiManagementBackend 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: functionApp.name
  parent: apiManagement
  properties: {
    resourceId: '${environment().resourceManager}${functionApp.id}'
    protocol: 'http'
    url: 'https://${functionApp.properties.hostNames[0]}/api'
    credentials: {
      header: {
        'x-functions-key': [
          '{{${apiManagementFunctionAppKey.name}}}'
        ]
      }
    }
  }
}

resource apiManagementFunctionAppApi 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  name: functionApp.name
  parent: apiManagement
  properties: {
    path: functionApp.name
    displayName: functionApp.name
    protocols: [
      'https'
    ]
    subscriptionRequired: false
  }
}

resource apiManagementFunctionAppApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: apiManagementFunctionAppApi
  properties: {
    format: 'xml'
    value: replace(loadTextContent('apim-policy-api.xml'), '{{BACKEND_NAME}}', apiManagementBackend.name)
  }
}

resource apiManagementhttpTriggeredFunctionOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'get-${httpTriggeredFunctionName}'
  parent: apiManagementFunctionAppApi
  properties: {
    displayName: httpTriggeredFunctionName
    method: 'GET'
    urlTemplate: '/${httpTriggeredFunctionName}'
  }
}

output apiManagementOperationUri string = '${apiManagement.properties.gatewayUrl}/${functionAppName}/${httpTriggeredFunctionName}'
