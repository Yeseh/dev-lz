@allowed(['', 'dev', 'test', 'acc', 'prod'])
@description('The environment this module is deployed to.')
param environment string

@description('The Azure resource location.')
param location string

@description('Shorthand name for making resource names')
param slug string

@description('The ID of the network security group.')
param networkSecurityGroupId string

@description('The prefixes for the VNET IP address.')
param vnetAddressPrefixes array 

@description('The prefix for the default subnet IP addresses.')
param subnetAddressPrefix string

@description('The DNS zones.')
param dnsZones array = [
  // 'privatelink.blob.${az.environment().suffixes.storage}'
  // 'privatelink.file.${az.environment().suffixes.storage}'
  // 'privatelink.queue.${az.environment().suffixes.storage}'
  // 'privatelink.table.${az.environment().suffixes.storage}'
  // 'privatelink${az.environment().suffixes.keyvaultDns}'
]

var vnetName = empty(environment)? 'vnet-${slug}' : 'vnet-${slug}-${environment}'

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: vnetName 
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
  }
}

module defaultSnet './subnet.bicep' = {
  name: 'defaultsnet-${vnet.name}'
  params: {
    vnetName: vnet.name
    subnetName: 'default'
    location: location
    addressPrefix: subnetAddressPrefix
    networkSecurityGroupId: networkSecurityGroupId
    enablePrivateEndpointNetworkPolicies: true
    serviceEndpointServices: [
      'Microsoft.Storage'
      'Microsoft.KeyVault'
    ]
  }
}

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zone in dnsZones: {
  name: zone 
  location: 'global' 
  dependsOn: [
    vnet
  ]
}]

resource pdnsVnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zone, i) in dnsZones: {
  name: last(split(vnet.id, '/'))
  location: 'global' 
  parent: privateDnsZones[i] 
  properties: {
    registrationEnabled: false 
    virtualNetwork: {
      id: vnet.id
    }
  }
}]

output vnetId string = vnet.id
output vnetName string = vnet.name
output defaultSnetId string = defaultSnet.outputs.snetId



