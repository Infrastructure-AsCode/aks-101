param workloadName string
param instanceId int
param vnetAddressPrefix string
param aksSubnetAddressPrefix string
param location string

var vnetName = '${workloadName}-vnet-${instanceId}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'aks'
        properties: {
          addressPrefix: aksSubnetAddressPrefix
        }
      }
    ]
  }
}

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: 'aks'    
  parent: vnet
  properties: {
    addressPrefix: aksSubnetAddressPrefix
  }
}

output aksSubnetId string = aksSubnet.id
output vnetName string = vnet.name
