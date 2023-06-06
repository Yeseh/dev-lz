param projectName string

@allowed(['dev', 'test', 'acc', 'prod'])
param environment string
param uamiId string
param deploymentTargetSubscriptionId string = subscription().subscriptionId

var contributor = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var storageAccountBlobDataOwner = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var keyVaultAdministrator = '00482a5a-887f-4fb3-b363-3b7fe8e74483'

resource project 'Microsoft.DevCenter/projects@2023-01-01-preview' existing = {
  name: projectName
}

resource projectEnvs 'Microsoft.DevCenter/projects/environmentTypes@2023-01-01-preview' = { 
  parent: project
  name: environment 
  properties: {
    deploymentTargetId: deploymentTargetSubscriptionId
    creatorRoleAssignment: {
      roles: {
        '${contributor}': {}
        '${storageAccountBlobDataOwner}': {}
        '${keyVaultAdministrator}': {}
      }
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}' : {}
    }
  }
}

output id string = projectEnvs.id
output name string = projectEnvs.name
