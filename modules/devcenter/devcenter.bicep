targetScope = 'resourceGroup'

param slug string
param location string= resourceGroup().location

var dcName = 'dc-${slug}'
var envTypes = ['dev', 'test', 'acc', 'prod']


resource uamiDev 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uami-${slug}-dev' 
  location: location
}

resource uamiTest 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uami-${slug}-test' 
  location: location
}

resource uamiAcc 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uami-${slug}-test' 
  location: location
}

resource uamiProd 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uami-${slug}-test' 
  location: location
}


resource dc 'Microsoft.DevCenter/devcenters@2023-01-01-preview' = {
  name: dcName 
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiDev.id}': {}
      '${uamiTest.id}': {}
      '${uamiAcc.id}': {}
      '${uamiProd.id}': {}
    }
  }
  properties: {}
}


resource envs 'Microsoft.DevCenter/devcenters/environmentTypes@2023-01-01-preview' = [for envType in envTypes: {
  parent: dc
  name: envType
}]

resource project 'Microsoft.DevCenter/projects@2023-01-01-preview' = {
  name: 'project-${slug}'
  location: location
  properties: {
    devCenterId: dc.id
    description: 'Project ${slug}'
    maxDevBoxesPerUser: 1
  }
}

module projectEnv './projectEnvironment.bicep' = {
  name: 'projectEnvs'
  params: {
    environment: 'dev'
    projectName: project.name 
    uamiId: uamiDev.id
  }
}

output dcName string = dc.name
output dcId string = dc.id
output projectId string = project.id
