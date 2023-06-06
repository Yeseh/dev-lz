targetScope = 'subscription'

param location string = 'westeurope'
@allowed(['dev', 'tst', 'acc', 'prd'])
param environment string = 'dev'
@description('The slug is used to create unique names for resources')
param slug string = 'devlz'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${slug}'
  location: location
}


module laws '../../modules/logWorkspace.bicep' = {
  scope: rg
  name: 'laws-devlz'
  params: {
    environment: environment
    location: location
    slug: slug
  }
}

module kv '../../modules/keyvault/keyvault.bicep' = {
  scope: rg
  name: 'kv-devlz'
  params: {
    location: location
    environment: environment
    logAnalyticsWorkspaceId: laws.outputs.workspaceId
    slug: slug
  }
}

module dc '../../modules/devcenter/devcenter.bicep' = {
  scope: rg 
  name: 'dc-devlz'
  params: {
    slug: slug
    location: location
  }
}
