param workloadName string
param instanceId int
param location string

var uniqueStr = uniqueString(subscription().subscriptionId)
var sbName = '${workloadName}-${uniqueStr}-sbns-${instanceId}'

resource sb 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: sbName
  location: location
  sku: {
    name: 'Basic'
  }
}

resource orderQueue 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = {
  name: 'orders'
  parent: sb
}

resource arOrderConsumer 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2021-06-01-preview' = {
  name: 'order-consumer'
  parent: orderQueue 
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource arKedaMonitor 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2021-06-01-preview' = {
  name: 'keda-monitor'
  parent: orderQueue 
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource arOrderGenerator 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2021-06-01-preview' = {
  name: 'order-generator'
  parent: orderQueue 
  properties: {
    rights: [
      'Send'
    ]
  }
}
