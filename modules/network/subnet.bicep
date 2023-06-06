
@description('VNet to create the subnet in')
param vnetName string
@description('The azure location for service endpoints')
param location string = resourceGroup().location
@description('The name of the service the subnet should be delegated to.')
param delegationService string = ''
@description('Serivce endpoints to enable on the subnet.')
param serviceEndpointServices string[] = [] 
@description('Name of the subnet')
param subnetName string
@description('Network security group ID to link to the vnet')
param networkSecurityGroupId string
@description('Address prefix for the subnet')
param addressPrefix string
param enablePrivateEndpointNetworkPolicies bool = false

var serviceEndpoints = map(serviceEndpointServices, (endpoint) => {
  locations: [location]
  service: endpoint
}) 

var delegations = delegationService != '' ? [{
  name: replace(delegationService, '/', '_')
  properties: {
    serviceName: delegationService
  }
}] : []

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: vnetName
}

resource snet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = {
  name: subnetName
  parent: vnet
  properties: {
    privateEndpointNetworkPolicies: enablePrivateEndpointNetworkPolicies ? 'Enabled' : 'Disabled'
    networkSecurityGroup: {
      id: networkSecurityGroupId
    }
    addressPrefix: addressPrefix 
    serviceEndpoints: serviceEndpoints
    delegations: delegations
  }
}

output snetId string = snet.id
