@description('The Azure resource location.')
param location string

@allowed(['', 'dev','tst','prd'])
@description('The environment this module is deployed to.')
param environment string

@description('The IP addresses that are allowed access.')
param whitelistIps array

param slug string

var nsgName = empty(environment) ? 'nsg-${slug}' : 'nsg-${slug}-${environment}'

var nsgRules = map(range(0, length(whitelistIps)), i => {
    name: 'Allow-${whitelistIps[i]}-Inbound'
    properties: {
      access: 'Allow'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRange: '*'
      direction: 'Inbound'
      priority: 200 + i 
      protocol: '*'
      sourceAddressPrefix: whitelistIps[i]
      sourcePortRange: '*'
    }
})

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: nsgName 
  location: location
  properties: {
    securityRules: nsgRules 
  } 
}

output nsgId string = nsg.id
output nsgName string = nsg.name
