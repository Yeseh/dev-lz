targetScope = 'resourceGroup'

param location string = resourceGroup().location 
param slug string 

resource uamiDev 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uami-${slug}-dev' 
  location: location
}

resource uamiTest 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uami-${slug}-test' 
  location: location
}

resource uamiAcc 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uami-${slug}-acc' 
  location: location
}

resource uamiProd 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uami-${slug}-prod' 
  location: location
}

output uamiDevId string = uamiDev.id
output uamiTestId string = uamiTest.id
output uamiAccId string = uamiAcc.id
output uamiProdId string = uamiAcc.id

output uamiDevName string = uamiDev.name
output uamiTestName string = uamiTest.name
output uamiAccName string = uamiAcc.name
output uamiProdName string = uamiAcc.name
