targetScope = 'resourceGroup'

type principalArray = {
  id: string
  type: 'User' | 'ServicePrincipal' | 'Group'
}[]

param storageAccountName string
param storageAccountContributors principalArray = []
param storageAccountBlobDataOwners principalArray = []
param storageAccountBlobDataContributors principalArray = []
param storageAccountBlobDataReaders principalArray = []
param storageAccountBlobDataDelegators principalArray = []

var storageAccountContributor = '17d1049b-9a84-46fb-8f53-869881c3d3ab'
var storageAccountBlobDataOwner = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var storageAccountBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageAccountBlobDataReader = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
var storageAccountBlobDelegator = 'db58b8e5-c6ad-4a2a-8342-4190687cbf4a'

module contributors '../roleAssignments/resourceGroupAssignments.bicep' = {
  name: 'blobContributors-${storageAccountName}'
  params: {
    roleDefinitionId: storageAccountContributor
    principals: storageAccountContributors
  }
}

module blobdatacontributors '../roleAssignments/resourceGroupAssignments.bicep' = {
  name: 'blobContributors-${storageAccountName}'
  params: {
    roleDefinitionId: storageAccountBlobDataContributor 
    principals: storageAccountBlobDataContributors 
  }
}

module blobdataowners '../roleAssignments/resourceGroupAssignments.bicep' = {
  name: 'blobOwners-${storageAccountName}'
  params: {
    roleDefinitionId: storageAccountBlobDataOwner 
    principals: storageAccountBlobDataOwners 
  }
}

module blobdatareaders '../roleAssignments/resourceGroupAssignments.bicep' = {
  name: 'blobReaders-${storageAccountName}'
  params: {
    roleDefinitionId: storageAccountBlobDataReader 
    principals: storageAccountBlobDataReaders 
  }
}

module blobdatadelegators '../roleAssignments/resourceGroupAssignments.bicep' = {
  name: 'blobDelegators-${storageAccountName}'
  params: {
    roleDefinitionId: storageAccountBlobDelegator
    principals: storageAccountBlobDataDelegators
  }
}

