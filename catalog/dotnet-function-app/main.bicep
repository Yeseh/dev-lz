targetScope = 'resourceGroup'

param environment string = 'dev'
param slug string 
param location string = resourceGroup().location
param vnetAddressPrefix string = '10.144.0.0/20'

var subnetAddressPrefix = cidrSubnet(vnetAddressPrefix, 24, 0)

module nsg '../../modules/network/nsg.bicep' = {
  name: 'nsg-${slug}-${environment}'
  params: {
    environment: environment
    location: location
    slug: slug
    whitelistIps: []
  }
}

module vnet '../../modules/network/vnet.bicep' = {
  name: 'vnet-${slug}-${environment}'
  params: {
    location: location
    environment: environment
    slug: slug
    networkSecurityGroupId: nsg.outputs.nsgId
    subnetAddressPrefix: subnetAddressPrefix 
    vnetAddressPrefixes: [vnetAddressPrefix]
  }
}

module law '../../modules/logWorkspace.bicep' = {
  name: 'law-${slug}-${environment}'
  params: {
    location: location
    environment: environment
    slug: slug
  }
}

module kv '../../modules/keyvault/keyvault.bicep' = {
  name: 'kv-${slug}-${environment}'
  params: {
    environment: environment
    location: location
    slug: slug 
    logAnalyticsWorkspaceId: law.outputs.workspaceId
  }
}

module asp '../../modules/apps/appServicePlan.bicep' = {
  name: 'asp-${slug}-${environment}' 
  params: {
    location: location
    slug: slug 
    environment: environment
  }
}

module fnApp '../../modules/apps/functionApp.bicep' = {
  name: 'fn-${slug}-${environment}' 
  params: {
    appServicePlanId: asp.outputs.id
    env: environment
    location: location
    logAnalyticsWorkspaceId: law.outputs.workspaceId
    slug: slug
  }
}
