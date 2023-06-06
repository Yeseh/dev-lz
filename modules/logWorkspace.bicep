
targetScope = 'resourceGroup'

@description('The Azure resource location.')
param location string = resourceGroup().location

param slug string

@allowed(['dev', 'tst', 'acc', 'prd'])
@description('The environment this module is deployed to.')
param environment string

var lawsName = 'laws-${slug}-${environment}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: lawsName 
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 0
    features: {
      enableLogAccessUsingOnlyResourcePermissions: false
    }
  }
}

output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
