targetScope = 'subscription'

@secure()
param sshPublicKey string
param ghPassword string
param rgName string

resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: rgName
  location: deployment().location
}

module server 'server.bicep' = {
  name: 'server'
  scope: rg
  params: {
    sshPublicKey: sshPublicKey
    ghPassword: ghPassword
  }
}
