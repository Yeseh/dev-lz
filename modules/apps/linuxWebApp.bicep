targetScope = 'resourceGroup'

@description('Azure location to deploy the resources to')
param location string = resourceGroup().location
@description('Project shorthand for building resource names')
param slug string
@description('ID of the subnet to integrate the function app with')
param integrationSnetId string 
@description('The resource ID of the log analytics workspace to stream function logs to')
param logAnalyticsWorkspaceId string
@description('The resource ID of the app service plan to use')
param appServicePlanId string
@allowed(['', 'dev', 'acc', 'tst', 'prd'])
@description('The environment this module is deployed to.')
param environment string
param alwaysOn bool = false
param enablePublicNetworkAccess bool = false
param appSettings object = {}
param azureAdB2cSettings object = {}
param azureAdSettings object = {}
param linuxFxVersion string = 'DOTNETCORE|6.0'

var webApiName = empty(environment) ? 'app-${slug}' : 'app-${slug}-${environment}'

var appSettingsConfigs = map(items(appSettings), i => {
  name: 'AppSettings__${i.key}'
  value: i.value 
})

var azureAdB2cConfigs = map(items(azureAdB2cSettings), i => {
  name: 'AzureAdB2C__${i.key}'
  value: i.value 
})
var azureAdConfigs = map(items(azureAdSettings), i => {
  name: 'AzureAd__${i.key}'
  value: i.value 
})

resource apiappInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-${webApiName}'
  location: location
  kind: 'other'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'CustomDeployment'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

var baseWebApiConfig = [
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: apiappInsights.properties.InstrumentationKey
  }
  {
    name: 'APPINSIGHTS_CONNECTION_STRING'
    value: apiappInsights.properties.ConnectionString
  }
  {
    name: 'WEBSITE_CONTENTOVERVNET'
    value: '1' 
  }
  {
    name: 'WEBSITE_VNET_ROUTE_ALL'
    value: '1' 
  }
  {
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: '1' 
  }
  {
    name: 'WEBSITE_DNS_SERVER'
    value: '168.63.129.16'
  }
  {
    name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
    value: 'true'
  }
]

var webapiConfig = concat(baseWebApiConfig, appSettingsConfigs, azureAdB2cConfigs, azureAdConfigs)

resource webapi 'Microsoft.Web/sites@2022-03-01' = {
  name: webApiName 
  location: location
  kind: 'linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: linuxFxVersion 
      alwaysOn: alwaysOn 
      appSettings: webapiConfig
    }
    httpsOnly: true
  }
}

resource webApi_virtualnetwork 'Microsoft.Web/sites/networkConfig@2022-03-01' = {
  parent: webapi 
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: integrationSnetId 
    swiftSupported: true
  }
}

resource webApiDiag  'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'webAPiDiag'
  scope: webapi 
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

output appServcieManagedIdentityPrincipalId string = webapi.identity.principalId


