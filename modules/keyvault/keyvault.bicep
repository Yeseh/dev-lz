targetScope = 'resourceGroup'

@description('The Azure resource location.')
param location string = resourceGroup().location

@maxLength(10)
@description('Small identifier for the project, used to build resource names.')
param slug string

@allowed(['', 'dev', 'test', 'acc', 'prod'])
@description('The environment this module is deployed to.')
param environment string = ''

@description('The Log Analytics Workspace ID to send keyvault logs to.')
param logAnalyticsWorkspaceId string

@description('The IP addresses that are allowed to communicate with the Key Vault.')
param whitelistIps array = []

@description('List of subnet IDs that are allowed to access the keyvault.')
param subnetIds array = []

@description('The ID of the subnet to place the KV private endpoint in. If empty, no private endpoint will be created.')
param privateEndpointSubnetId string = ''

@description('The ID of the private DNS zone.')
param privateDnsZoneId string = ''

@description('Whether to enable purge protection')
param enablePurgeProtection bool = true

param allowPublicAccess bool = false

var kvIpRules = map(range(0, length(whitelistIps)), i => {
  value: '${whitelistIps[i]}'
})

var kvSubnetRules = map(range(0, length(subnetIds)), i => {
  id: '${subnetIds[i]}'
})

var kvName = empty(environment) ? 'kv-${slug}' : 'kv-${slug}-${environment}'
var privateEndpointName = 'pep-${kvName}'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: kvName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: true
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: allowPublicAccess ? 'Allow' : 'Deny'
      virtualNetworkRules: kvSubnetRules 
      ipRules: kvIpRules
    }
    enablePurgeProtection: enablePurgeProtection 
    softDeleteRetentionInDays: 7
    enableSoftDelete: true
  }
}

resource keyVaultDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'keyVaultDiagnosticSettings'
  scope: keyVault
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

resource keyVaultPep 'Microsoft.Network/privateEndpoints@2022-05-01' = if (!empty(privateEndpointSubnetId)) {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId 
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource keyvaultPdnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = if (!empty(privateEndpointSubnetId)) {
  name: 'kvPrivateDns'
  parent: keyVaultPep
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'vault'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output name string = keyVault.name
output vaultUri string = keyVault.properties.vaultUri
