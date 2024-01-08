param vnetSourceName string
param vnetDestinationName string
param vnetSourceResourceGroupName string
param vnetDestinationResourceGroupName string
param vnetDestinationSubscriptionId string
param vnetSourceSubscriptionId string
param allowGatewayTransit bool = true
param useRemoteGateways bool
param allowForwardedTraffic bool = true
param allowVirtualNetworkAccess bool = true


resource vnetSourceResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: vnetSourceResourceGroupName
  scope: subscription(vnetSourceSubscriptionId)
}

resource vnetDestinationResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: vnetDestinationResourceGroupName
  scope: subscription(vnetDestinationSubscriptionId)
}

resource vnetSource 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetSourceName
  scope: vnetSourceResourceGroup
}

resource vnetDestination 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetDestinationName
  scope: vnetDestinationResourceGroup
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-06-01' = {
  //disable linter warning for this construction
  //in this case its correct due to the scope of the deployment
  #disable-next-line use-parent-property
  name: '${vnetSource.name}/${vnetSource.name}-To-${vnetDestination.name}'
  properties: {
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: vnetDestination.id
    }
  }
}
