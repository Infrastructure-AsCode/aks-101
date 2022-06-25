param workloadName string
param location string

var prefixForACR = replace(workloadName, '-', '')
var uniqueStr = uniqueString(subscription().subscriptionId)
var acrName = '${prefixForACR}${uniqueStr}acr'

resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
}

output acrId string = acr.id
output acrName string = acr.name
