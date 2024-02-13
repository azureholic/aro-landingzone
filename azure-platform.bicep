//This is the bicep for the Azure Platform team
//it deploys a vnet peered with the Hub VNET for
//deploying an Azure Redhat OpenShift cluster
//the target subscription for this deployment should be the 
//subscription where the Cluster will be deployed

param environmentName string
param servicePrincipalId string
param vnetHubResourceGroupName string
param vnetHubName string
param vnetHubSubscriptionId string
param lzNetworkResourceGroupName string
param location string
param spokeVnetName string
param spokeVnetAddressPrefix string
param spokeSubnets array
param tagValues object = {}
param firewallIpAddress string = ''
param dnsServers array 

//constants - do not change
var NetworkContributor = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var aroResourceProviderObjectId = '1679a87a-3db8-4d2a-af43-79d10ff9006c'

// Setting target scope
targetScope = 'subscription'

// Creating resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${lzNetworkResourceGroupName}-${environmentName}'
  location: location
  tags: tagValues
}

resource rgHub 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: vnetHubResourceGroupName
  scope: subscription(vnetHubSubscriptionId)
}

//deploy a route table
module routeTable 'modules/networking/routetable.bicep' = {
  name: 'route-table-deployment'
  scope: rg
  params: {
    name: '${spokeVnetName}-${environmentName}-rt'
    location: location
    tagValues: tagValues
  }
}

//if firewallIpAddress is not empty, deploy a route to the firewall
module route 'modules/networking/route.bicep' = if (firewallIpAddress != '') {
  name: 'route-deployment'
  scope: rg
  params: {
    routeTableName: routeTable.outputs.routeTableName
    routeName: 'force-firewall'
    addressPrefix: '0.0.0.0/0'
    nextHopIpAddress: firewallIpAddress
    nextHopType: 'VirtualAppliance'
  }
}

// Deploying the VNET
module vnet 'modules/networking/vnet.bicep' = {
  dependsOn: [
    routeTable
  ]
  name: 'vnet-deployment'
  scope: rg
  params: {
    vnetName: '${spokeVnetName}-${environmentName}'
    location: location
    subnets: spokeSubnets
    vnetAddressPrefix: spokeVnetAddressPrefix
    tagValues: tagValues
    routeTableName: '${spokeVnetName}-${environmentName}-rt'
    dnsServers: dnsServers
  }
}

// Deploying the VNET peering
module peeringSpokeToHub 'modules/networking/vnetpeering.bicep' = {
  name: 'peering-spoke-to-hub-deployment'
  scope: rg
  params: {
    vnetDestinationName: vnetHubName
    vnetDestinationResourceGroupName: vnetHubResourceGroupName
    vnetDestinationSubscriptionId: vnetHubSubscriptionId
    vnetSourceName: vnet.outputs.name
    vnetSourceResourceGroupName: rg.name
    vnetSourceSubscriptionId: subscription().subscriptionId
    useRemoteGateways: true
  }
}

module peeringHubToSpoke 'modules/networking/vnetpeering.bicep' = {
  name: 'peering-hub-to-spoke-deployment'
  scope: rgHub
  params: {
    vnetDestinationName: vnet.outputs.name
    vnetDestinationResourceGroupName: rg.name
    vnetDestinationSubscriptionId: subscription().subscriptionId
    vnetSourceName: vnetHubName
    vnetSourceResourceGroupName: rgHub.name
    vnetSourceSubscriptionId: vnetHubSubscriptionId
    useRemoteGateways: false
  }
}

//Set RBAC permissions for the service principal
module setNetworkContributorVnet 'modules/roleAssignments/roleassignment.bicep' = {
  name: 'set-network-contributor-vnet'
  scope: rg
  dependsOn: [ vnet, peeringSpokeToHub, peeringHubToSpoke ]
  params: {
    deploymentName: 'set-network-contributor-ARM-vnet'
    principalId: servicePrincipalId
    roleDefinitionId: NetworkContributor
    targetResourceId: vnet.outputs.resourceId
  }
}

module setNetworkContributorRouteTable 'modules/roleAssignments/roleassignment.bicep' = {
  name: 'set-network-contributor-rt'
  scope: rg
  dependsOn: [ routeTable ]
  params: {
    deploymentName: 'set-network-contributor-ARM-rt'
    principalId: servicePrincipalId
    roleDefinitionId: NetworkContributor
    targetResourceId: routeTable.outputs.resourceId
  }
}

//Set RBAC permissions for the resource provider
module setNetworkContributorAroRpVnet 'modules/roleAssignments/roleassignment.bicep' = {
  name: 'set-network-contributor-arorp-vnet'
  scope: rg
  dependsOn: [ setNetworkContributorVnet ]
  params: {
    deploymentName: 'set-network-contributor-ARM-arorp-vnet'
    principalId: aroResourceProviderObjectId
    roleDefinitionId: NetworkContributor
    targetResourceId: vnet.outputs.resourceId
  }
}

module setNetworkContributorAroRpRt 'modules/roleAssignments/roleassignment.bicep' = {
  name: 'set-network-contributor-arorp-rt'
  scope: rg
  dependsOn: [ setNetworkContributorRouteTable ]
  params: {
    deploymentName: 'set-network-contributor-ARM-arorp-rt'
    principalId: aroResourceProviderObjectId
    roleDefinitionId: NetworkContributor
    targetResourceId: routeTable.outputs.resourceId
  }
}
