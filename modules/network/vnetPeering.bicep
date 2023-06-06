@description('Name of the VNET to be peered with.')
param vnetName string

@description('The peer VNET name.')
param peerVnetName string

@description('The ID of the peer VNET.')
param peerVnetId string

@description('Indicates whether virtual network access is allowed.')
param allowVirtualNetworkAccess bool = true

@description('Indicates whether gateway transit is allowed.')
param allowGatewayTransit bool = false 

@description('Indicates whether forwarded traffic is allowed.')
param allowForwardedTrafic bool = false

@description('Indicates remote gateways should be used.')
param useRemoteGateways bool = false 

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  name: vnetName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-05-01' = {
  name: 'peer-${vnetName}-to-${peerVnetName}'
  parent: vnet 
  properties: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess 
    allowForwardedTraffic: allowForwardedTrafic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    doNotVerifyRemoteGateways: false
    remoteVirtualNetwork: {
      id: peerVnetId
    }
  }
}
