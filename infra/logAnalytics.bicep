param workloadName string
param instanceId int
param location string

var uniqueStr = uniqueString(subscription().subscriptionId, resourceGroup().id)
var logAnalyticsWorkspaceName = '${workloadName}-${uniqueStr}-la-${instanceId}'

var logAnalyticsRetentionInDays = 60

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logAnalyticsRetentionInDays
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
