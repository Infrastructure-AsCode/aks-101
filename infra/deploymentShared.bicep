targetScope = 'subscription'
param workloadName string
param location string = 'westeurope'

var resourceGroupName = '${workloadName}-rg'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module acr 'acrShared.bicep' = {
  scope: resourceGroup
  name: 'acr'
  params: {
    workloadName: workloadName
    location: location
  }
}

output acrName string = acr.outputs.acrName
