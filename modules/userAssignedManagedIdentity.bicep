targetScope = 'resourceGroup'

param location string = resourceGroup().location
param name string

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
}

output id string = uami.id
output name string = uami.name
