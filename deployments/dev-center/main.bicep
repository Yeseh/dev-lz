targetScope = 'subscription'

param location string = 'westeurope'
@allowed(['','dev', 'tst', 'acc', 'prd'])
param environment string = 'dev'
@description('The slug is used to create unique names for resources')
param slug string = 'devlz'
param ipWhitelist array = []
param catalogRepoUrl string

var owner = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${slug}'
  location: location
}

module mi 'managedIdentitites.bicep' = {
  scope: rg
  name: 'userAssignedManagedIdentities'
  params: {
    slug: slug
    location: location
  }
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
    whitelistIps: ipWhitelist 
    allowPublicAccess: true
  }
}

module dc '../../modules/devcenter/devcenter.bicep' = {
  scope: rg 
  name: 'dc-devlz'
  params: {
    slug: slug
    location: location
    githubPatIdentifier: '${kv.outputs.vaultUri}secrets/${slug}-catalog-pat'
    githubRepoUri: catalogRepoUrl
  }
}

module kvRoleAssignments '../../modules/keyvault/roleAssignments.bicep' = {
  scope: rg
  name: 'ra-kvsecretusers'
  params: {
    kvName: kv.outputs.name
    secretsUsers: [{
      id: dc.outputs.dcSystemManagedIdentity
      type: 'ServicePrincipal'
    }]
  }
}

module subRoleAssignments '../../modules/roleAssignments/subscriptionAssignments.bicep' = {
  name: 'dcmi-subscriptionowner' 
  params: {
    roleDefinitionId: owner
    principals: [
      {
        id: dc.outputs.dcSystemManagedIdentity
        type: 'ServicePrincipal'
      }
    ]
  }
}
