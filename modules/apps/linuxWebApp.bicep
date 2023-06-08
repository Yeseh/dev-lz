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
@allowed(['', 'dev', 'acc', 'test', 'prod'])
@description('The environment this module is deployed to.')
param environment string = ''
@allowed(['DOTNETCORE|6.0', 'Node|18', 'Python|3.10', 'Java|17', 'custom'])
param linuxFxVersion string = 'DOTNETCORE|6.0'
@allowed(['DOTNETCORE|6.0', 'Node|18', 'Python|3.10', 'Java|17', 'custom'])
param windowsFxVersion string = 'DOTNETCORE|6.0'
@allowed(['linux', 'windows'])
param kind string = 'linux'
@description('Always on')
param alwaysOn bool = false
@description('Enable public network access')
param enablePublicNetworkAccess bool = false
@description('App settings to configure the function app with')
param appSettings object = {}
@description('Azure AD B2C settings to configure the function app with')
param azureAdB2cSettings object = {}
@description('Azure AD settings to configure the function app with')
param azureAdSettings object = {}

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

var appServiceConfig = concat(baseWebApiConfig, appSettingsConfigs, azureAdB2cConfigs, azureAdConfigs)

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: webApiName 
  location: location
  kind: kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: linuxFxVersion 
      windowsFxVersion: windowsFxVersion
      alwaysOn: alwaysOn 
      appSettings: appServiceConfig
    }
    httpsOnly: true
  }
}

resource appServiceVirtualNetwork 'Microsoft.Web/sites/networkConfig@2022-03-01' = {
  parent: appService 
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: integrationSnetId 
    swiftSupported: true
  }
}

resource appServiceDiag  'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'appServieDiag-${webApiName}}'
  scope: appService 
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

output appServiceManagedIdentityPrincipalId string = appService.identity.principalId
output appServiceUrl string = appService.properties.defaultHostName


