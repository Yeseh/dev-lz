targetScope = 'resourceGroup'

type principalArray = {
  id: string
  type: 'User' | 'ServicePrincipal' | 'Group'
}[]

@description('Array of objects containing the id and type of the service principals to assign the role to')
param principals principalArray = []

@description('The role definition ID to assign')
param roleDefinitionId string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: roleDefinitionId 
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (principal, i) in principals: {
  name: guid(resourceGroup().id, principal.id, roleDefinitionId)
  scope: resourceGroup()
  properties: {
    principalId: principal.id 
    roleDefinitionId: roleDefinition.id 
    principalType: principal.type
  }
}]
