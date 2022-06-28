param workloadName string
param instanceId int
param aksSubnetId string
param location string

var aksMIName = '${workloadName}-aks-mi-${instanceId}' 
var aksName = '${workloadName}-aks-${instanceId}'

resource aksMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: aksMIName
  location: location
}

resource aks 'Microsoft.ContainerService/managedClusters@2021-05-01' = {
  name: aksName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksMI.id}': {}
    }
  }
  properties: {
    dnsPrefix: aksName
    enableRBAC: true    
    kubernetesVersion: '1.23.5'    
    agentPoolProfiles: [
      {
        name: 'system'
        count: 2
        vmSize: 'Standard_DS2_v2'
        vnetSubnetID: aksSubnetId
        osType: 'Linux'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
      }
    ]    
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      networkPolicy: 'calico'
    }
    podIdentityProfile: {
      enabled: true
      userAssignedIdentities: []
      userAssignedIdentityExceptions: [
        {
          name: 'flux-extension-exception'
          namespace: 'flux-system'
          podLabels: {
            'app.kubernetes.io/name': 'flux-extension'
          }
        }
      ]
    }
  }
}


// resource fluxExtension 'Microsoft.KubernetesConfiguration/extensions@2022-04-02-preview' = {
//   name: 'flux'
//   scope: aks
//   properties: {
//     autoUpgradeMinorVersion: true
//     configurationProtectedSettings: {}
//     configurationSettings: {
//       'helm-controller.enabled': 'true'
//       'source-controller.enabled': 'true'
//       'kustomize-controller.enabled': 'true'
//       'notification-controller.enabled': 'true'
//       'image-automation-controller.enabled': 'true'
//       'image-reflector-controller.enabled': 'true'
//     }
//     extensionType: 'microsoft.flux'
//     releaseTrain: 'Stable'
//     scope: {
//       cluster: {
//         releaseNamespace: 'flux-system'
//       }
//     }
//   }
// }

// resource fluxConfiguration 'Microsoft.KubernetesConfiguration/fluxConfigurations@2022-01-01-preview' = {
//   name: 'bicep-fluxconfig'
//   scope: aks
//   properties: {
//     namespace: 'cluster-config'
//     scope: 'cluster'
//     sourceKind: 'GitRepository'
//     configurationProtectedSettings: {}
//     gitRepository: {
//       repositoryRef: {
//         branch: 'main'
//       }
//       syncIntervalInSeconds: 120
//       timeoutInSeconds: 600
//       url: 'https://github.com/evgenyb/gitops-flux2-kustomize.git'
//     }
//     kustomizations: {      
//       'infra': {
//         path: './infrastructure'
//         syncIntervalInSeconds: 120
//       }
//     }
//   }
//   dependsOn: [
//     fluxExtension
//   ]
// }


output aksKubeletIdentityObjectId string = aks.properties.identityProfile.kubeletidentity.objectId
output aksMIPrincipalId string = aksMI.properties.principalId
