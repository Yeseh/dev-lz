targetScope = 'resourceGroup'

param environment string = 'dev'
param slug string 
param location string = resourceGroup().location

module law '../../modules/logWorkspace.bicep' = {
  name: 'lawdevlzdemo1' 
  params: {
    location: location
    environment: environment
    slug: slug
  }
}

module kv '../../modules/keyvault/keyvault.bicep' = {
  name: 'kvdevlzdemo1'
  params: {
    environment: environment
    location: location
    slug: slug 
    logAnalyticsWorkspaceId: law.outputs.workspaceId
  }
}

module sa '../../modules/storage/account.bicep' = {
  name: 'sadevlzdemo1' 
  params: {
    containerNames: ['dev']
    environment: environment 
    keyVaultName: kv.outputs.name
    keyVaultResourceGroup: resourceGroup().name
    location: location 
    logAnalyticsWorkspaceId: law.outputs.workspaceId
    slug: slug 
    whitelistIps: []
  }
}
