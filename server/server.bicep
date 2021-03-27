@description('SSH public key for the Virtual Machines.')
@secure()
param sshPublicKey string

@description('Gohop password.')
param ghPassword string

var publicIPAddresseName = 'goserver-ip'
var adminUsername = 'azureuser'
var osImagePublisher = 'Canonical'
var osImageOffer = 'UbuntuServer'
var osImageSKU = '18.04-LTS'
var virtualMachineName = 'goserver'
var networkInterfaceName = 'goserver-nic'
var networkSecurityGroupName = 'goserver-nsg'
var virtualNetworkName = 'goserver-vnet'
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var storageAccountType = 'StandardSSD_LRS'
var storageAccountName = uniqueString(resourceGroup().id, deployment().name)
var scriptUrlBase = 'https://raw.githubusercontent.com/haha1903/ghpair/master'
var scriptName = 'server.sh'
var scriptUrl = '${scriptUrlBase}/server/${scriptName}'

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: virtualMachineName
  location: resourceGroup().location
  tags: {}
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_A1_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osImageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineName}-osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}

resource virtualMachineConfig 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${virtualMachine.name}/config'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'CustomScriptForLinux'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrl
      ]
      commandToExecute: 'sh ${scriptName} ${scriptUrlBase} ${ghPassword}'
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: networkInterfaceName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.1.0.4'
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: publicIPAddresse.id
          }
          subnet: {
            id: '${virtualNetwork.id}/subnets/default'
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-08-01' = {
  name: networkSecurityGroupName
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'gohop'
        properties: {
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '1024-50000'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource publicIPAddresse 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: publicIPAddresseName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: virtualNetworkName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
    ]
  }
}
