targetScope = 'subscription'
param workloadName string
param instanceId int
param sharedAcrName string
param location string = 'westeurope'

var vnetAddressPrefix = '10.${instanceId}.0.0/16'
var aksSubnetAddressPrefix = '10.${instanceId}.0.0/23'

var resourceGroupName = '${workloadName}-rg-${instanceId}'
var sharedResourceGroupName = '${workloadName}-rg'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

resource sharedResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: sharedResourceGroupName
}

module appInsights 'appInsights.bicep' = {
  scope: resourceGroup
  name: 'appInsights'
  params: {
    workloadName: workloadName
    instanceId: instanceId
    location: location
  }
}

module acr 'acr.bicep' = {
  scope: resourceGroup
  name: 'acr'
  params: {
    workloadName: workloadName
    instanceId: instanceId
    location: location
  }
}

module logAnalytics 'logAnalytics.bicep' = {
  scope: resourceGroup
  name: 'logAnalytics'
  params: {
    workloadName: workloadName
    instanceId: instanceId
    location: location
  }
}

module vnet 'vnet.bicep' = {
  scope: resourceGroup
  name: 'vnet'
  params: {
    workloadName: workloadName
    instanceId: instanceId
    location: location
    vnetAddressPrefix: vnetAddressPrefix
    aksSubnetAddressPrefix: aksSubnetAddressPrefix
  }
}

module aks 'aks.bicep' = {
  scope: resourceGroup
  name: 'aks'
  params: {
    workloadName: workloadName
    instanceId: instanceId
    location: location
    aksSubnetId: vnet.outputs.aksSubnetId
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

module aksRoles 'grantAKSPermissions.bicep' = {
  name: 'aksRoles'
  scope: resourceGroup
  params: {
    vnetName: vnet.outputs.vnetName
    principalId: aks.outputs.aksMIPrincipalId
  }
}

module acrToAks 'attachACRToAKS.bicep' = {
  scope: resourceGroup
  name: 'acrToAks'
  params: {
    acrName: acr.outputs.acrName
    aksKubeletIdentityObjectId: aks.outputs.aksKubeletIdentityObjectId
  }
}

module sharedAcrToAks 'attachACRToAKS.bicep' = {
  scope: sharedResourceGroup
  name: 'sharedAcrToAks'
  params: {
    acrName: sharedAcrName    
    aksKubeletIdentityObjectId: aks.outputs.aksKubeletIdentityObjectId
  }
}
