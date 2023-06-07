param projectName string
param location string
param devCenterId string
param description string = ''

param environments array = []
// Roles for environment creators, set with defaults that allow most operations
param creatorRoles array = [
  // Contributor
  'b24988ac-6180-42a0-ab88-20f7382dd24c'
  // Storage blob data contributor
  'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
  // Key vault administrator
  '00482a5a-887f-4fb3-b363-3b7fe8e74483'
]
param deploymentTargetSubscriptionId string = subscription().subscriptionId

resource project 'Microsoft.DevCenter/projects@2023-01-01-preview' = {
  name: projectName
  location: location
  properties: {
    description: empty(description) ? projectName : description
    devCenterId: devCenterId
    maxDevBoxesPerUser: 1
  }
}

var roles = toObject(creatorRoles, role => role, val => {})

var deploymentTarget = '/subscriptions/${deploymentTargetSubscriptionId}'

resource projectEnvs 'Microsoft.DevCenter/projects/environmentTypes@2023-01-01-preview' = [for env in environments: {  
  parent: project
  name: env 
  properties: {
    deploymentTargetId: deploymentTarget
    status: 'Enabled'
    creatorRoleAssignment: {
      roles: roles 
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}]

output projectId string = project.id
output projectName string = project.name
