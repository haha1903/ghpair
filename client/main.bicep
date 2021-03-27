targetScope = 'subscription'

param rgName string
@secure()
param sshPublicKey string
param ghServer string
param ghPassword string
param ssPassword string
param ssPort string

resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: rgName
  location: deployment().location
}

module client 'client.bicep' = {
  name: 'client'
  scope: rg
  params: {
    sshPublicKey: sshPublicKey
    ghPassword: ghPassword
    ssPassword: ssPassword
    ssPort: ssPort
    ghServer: ghServer
  }
}
