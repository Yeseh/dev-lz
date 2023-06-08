targetScope = 'resourceGroup'

@description('Azure location to deploy the resources to')
param location string = resourceGroup().location
@description('The resource ID of the log analytics workspace to stream function logs to')
param logAnalyticsWorkspaceId string
@description('The resource ID of the app service plan to use')
param appServicePlanId string
@description('The name of the function app, without prefixes')
param slug string
@allowed(['dev', 'prd'])
@description('The environment this module is deployed to.')
param env string
@description('ID of the subnet to delegate to the function app')
param delegationSubnetId string = ''
@description('The runtime to use for the function app')
@allowed(['dotnet', 'dotnet-isolated', 'node', 'python', 'java', 'custom'])
param functionWorkerRuntime string = 'dotnet'
@maxValue(10)
@description('The number of function worker processes to run')
param functionWorkerProcessCount int = 1
param whitelistIps array = []

var functionAppName = 'fn-${slug}-${env}'
var dehyphenatedAppName = replace(functionAppName, '-', '')
var storageAccountName = 'st${dehyphenatedAppName}'

var storageIpRules = map(range(0, length(whitelistIps)), i => {
  action: 'Allow'
  value: whitelistIps[i]
})


// var securityRestrictions = map(range(0, length(whitelistIps)), i => {
//   ipAddress: '${whitelistIps[i]}/32'
//   priority: i + 500
//   action: 'Allow'
//   name: 'Allow${whitelistIps[i]}'
// })

resource fnStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location 
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'	
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false 
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: storageIpRules
      virtualNetworkRules: [{
        id: delegationSubnetId
      }]
    }
  }

  resource fileService 'fileServices' =  {
    name: 'default'

    resource fnShare 'shares' = {
      name: toLower(functionAppName)
    }
  }
}


resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-${functionAppName}'
  location: location
  kind: 'other'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'CustomDeployment'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

resource fnApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    serverFarmId: appServicePlanId
    siteConfig: {
      // TODO: These should be enabled, but requires more work with github actions
      // ipSecurityRestrictions: securityRestrictions
      // scmIpSecurityRestrictions: []
      // scmIpSecurityRestrictionsUseMain: false
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${fnStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${fnStorage.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${fnStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${fnStorage.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'FUNCTIONS_WORKER_PROCESS_COUNT'
          value: '${functionWorkerProcessCount}'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1' 
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1' 
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
      ]
    }
  }
}


resource functionAppName_virtualNetwork 'Microsoft.Web/sites/networkConfig@2022-03-01' = if (delegationSubnetId != '') { 
  parent: fnApp 
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: delegationSubnetId 
    swiftSupported: true
  }
}

resource fnAppDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'fnAppDiag'
  scope: fnApp 
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

output functionAppManagedIdentityPrincipalId string = fnApp.identity.principalId
output functionAppId string = fnApp.id
output functionAppUrl string = fnApp.properties.defaultHostName


