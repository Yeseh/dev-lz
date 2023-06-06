targetScope = 'resourceGroup'

type principalArray = {
  id: string
  type: 'User' | 'ServicePrincipal' | 'Group'
}[]

@description('The name of the key vault to assign the role to')
param kvName string
@description('Array of objects containing the id and type (User|ServicePrincipal|Group) of the service principal to assign the role to')
param secretsOfficers principalArray = []
param secretsUsers principalArray = []
param certificateOfficers principalArray = []
param administrators principalArray = []

var keyVaultSecretsOfficer = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
var keyVaultSecretsUser = '4633458b-17de-408a-b874-0445c86b69e6'
var keyVaultCertificateOfficer = 'a4417e6f-fecd-4de8-b567-7b0420556985'
var keyVaultAdministrator = '00482a5a-887f-4fb3-b363-3b7fe8e74483'

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: kvName 
}

module officers '../roleAssignments/resourceGroupAssignment.bicep' = {
  name: 'keyVaultSecretsOfficers-${keyVault.name}'
  params: {
    roleDefinitionId: keyVaultSecretsOfficer
    principals: secretsOfficers
  }
}

module secretUsers '../roleAssignments/resourceGroupAssignment.bicep' = {
  name: 'keyVaultSecretUsers-${kvName}'
  params: {
    roleDefinitionId: keyVaultSecretsUser 
    principals: secretsUsers 
  }
}

module certOfficers '../roleAssignments/resourceGroupAssignment.bicep' = {
  name: 'keyVaultSecretUsers-${kvName}'
  params: {
    roleDefinitionId: keyVaultCertificateOfficer 
    principals: certificateOfficers 
  }
}

module admins '../roleAssignments/resourceGroupAssignment.bicep' = {
  name: 'keyVaultAdministrators-${kvName}'
  params: {
    roleDefinitionId: keyVaultAdministrator 
    principals: administrators 
  }
}
