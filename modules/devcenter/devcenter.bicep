targetScope = 'resourceGroup'

param slug string
param location string= resourceGroup().location
param githubRepoUri string
param githubPatIdentifier string

var dcName = 'dc-${slug}'
var envTypes = ['dev', 'test', 'acc', 'prod']

resource dc 'Microsoft.DevCenter/devcenters@2023-01-01-preview' = {
  name: dcName 
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

resource envs 'Microsoft.DevCenter/devcenters/environmentTypes@2023-01-01-preview' = [for envType in envTypes: {
  parent: dc
  name: envType
}]

resource catalog 'Microsoft.DevCenter/devcenters/catalogs@2023-01-01-preview' = {
  parent: dc
  name: 'Catalog-${slug}'
  properties:{
    gitHub: {
      branch: 'main'
      uri: githubRepoUri
      secretIdentifier: githubPatIdentifier     
      path: 'catalog'
    }
  }
}

module project './project.bicep' = {
  name: 'projects'
  params: {
    devCenterId: dc.id 
    location: location 
    projectName: 'project-${slug}'
    environments: ['dev', 'test', 'acc', 'prod']
  }
}

output dcName string = dc.name
output dcId string = dc.id
output dcSystemManagedIdentity string = dc.identity.principalId
output projectId string = project.outputs.projectId
