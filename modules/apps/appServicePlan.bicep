@allowed(['', 'test', 'acc', 'dev', 'prod'])
@description('The environment this module is deployed to.')
param environment string = ''
param location string = resourceGroup().location
param slug string
@allowed(['linux', 'windows'])
param kind string = 'linux'
param sku object = {name: 'B1', tier: 'Basic'}

var aspName = empty(environment) ? 'asp-${slug}' : 'asp-${slug}-${environment}'

resource asp 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: aspName 
  location: location 
  kind: kind
  properties: {
    reserved: kind == 'linux'
  }
  sku: sku
}

output id string = asp.id
