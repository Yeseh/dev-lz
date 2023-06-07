@description('The name of the Key Vault in which this secret should be stored.')
param keyVaultName string

@description('The name of the secret.')
param secretName string

@secure()
@description('The value of the secret.')
param secretValue string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: secretName
  parent: keyVault
  properties: {
    value: secretValue
  }
}
