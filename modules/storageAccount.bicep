targetScope = 'resourceGroup'

@description('The Azure resource location.')
param location string

@allowed(['tst', 'acc', 'prd'])
@description('The environment this module is deployed to.')
param environment string

@description('The ID of the Log Analytics Workspace, to send diagnostics to.')
param logAnalyticsWorkspaceId string

@description('The IP addresses allowed to access this storage account.')
param whitelistIps array

@description('Small identifier for the project, used to build resource names.')
param slug string

@description('An array of containers that need to be created.')
param containerNames array

@description('The Key Vault name where the storage account access key will be stored.')
param keyVaultName string

@description('The name of the resource group the Key Vault is in.')
param keyVaultResourceGroup string

@description('The IDs of the subnets this storage account is connected to.')
param subnetIds array = []

@description('The ID of the subnet to place the KV private endpoint in. If empty, no private endpoint will be created.')
param privateEndpointSubnetId string = ''

@description('The ID of the DNS zone used for blob services.')
param privateDnsZoneId string = ''

var saIpRules = map(range(0, length(whitelistIps)), i => {
  action: 'Allow'
  value: whitelistIps[i]
})

var saSubnetRules = map(range(0, length(subnetIds)), i => {
  id: subnetIds[i]
})

var isTestEnvironment = environment == 'tst' || environment == 'dev'
var storageAccountName = toLower('sa${slug}${environment}')
var privateEndpointName = 'pep-${storageAccountName}'
var secretName = '${storageAccountName}-access-key'

var deleteRetentionDays = isTestEnvironment ? 7 : 30
// Must be at least 1 day less than deleteRetentionDays
var restorePolicyDays = isTestEnvironment ? 6 : 29

resource storageaccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName 
  location: location
  kind: 'StorageV2'
  sku: {
    name:'Standard_LRS'
  }
  properties: {
    accessTier: 'Cool'
    minimumTlsVersion: 'TLS1_2'
    allowedCopyScope: 'AAD'
    largeFileSharesState: 'Disabled'
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true 
    allowSharedKeyAccess: true
    allowBlobPublicAccess: false
    isNfsV3Enabled: false
    allowCrossTenantReplication: false
    isSftpEnabled: false
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: saIpRules
      virtualNetworkRules: saSubnetRules
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  parent: storageaccount
  name: 'default'
  properties: {
    isVersioningEnabled: true 
    changeFeed: {
      enabled: true 
      // null = 'infinite' retention of change feed 
      retentionInDays: isTestEnvironment ? 7 : null
    }
    containerDeleteRetentionPolicy: {
      allowPermanentDelete: false 
      enabled: true
      days: deleteRetentionDays 
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false 
      enabled: true 
      days: deleteRetentionDays 
    }
    restorePolicy: {
      enabled: true 
      days: restorePolicyDays 
    }
  }
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = [for containerName in containerNames: {
  parent: blobService
  name: containerName
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    publicAccess: 'None'
  }
}]

module keyVaultSecret './keyvault/keyVaultSecret.bicep' = {
  name: secretName
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    keyVaultName: keyVaultName
    secretName: secretName
    secretValue: storageaccount.listKeys().keys[0].value
  }
}

resource blobserviceDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'blobServiceDiag'
  scope: blobService 
  properties: {
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

resource storageaccountDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'storageaccountDiag'
  scope: storageaccount
  properties: {
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

resource saPep 'Microsoft.Network/privateEndpoints@2022-05-01' = if (!empty(privateEndpointSubnetId)) {
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
          privateLinkServiceId: storageaccount.id 
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
  dependsOn: [
    blobService
  ]

  resource saPdnszoneGroup 'privateDnsZoneGroups' = {
    name: 'pdnsZoneGroup-${storageaccount.name}'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'blob'  
          properties: {
            privateDnsZoneId: privateDnsZoneId 
          }
        }
      ]
    }
  }
}

resource saDeleteLock 'Microsoft.Authorization/locks@2020-05-01' = if (!isTestEnvironment) {
  name: 'CanNotDelete-${storageAccountName}'
  scope: storageaccount
  properties: {
    level: 'CanNotDelete'
  }
}

output storageAccountId string = storageaccount.id
output storageAccountName string = storageaccount.name

