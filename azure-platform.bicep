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

var NetworkContributor = '4d97b98b-1d4f-4787-a291-c67834d212e7'

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

// Deploying storage account using module
module vnet 'modules/networking/vnet.bicep' = {
  name: 'vnet-deployment'
  scope: rg    
  params: {
    vnetName: '${spokeVnetName}-${environmentName}'
    location: location
    subnets: spokeSubnets
    vnetAddressPrefix: spokeVnetAddressPrefix
    tagValues: tagValues
  }
}

module peeringSpokeToHub 'modules/networking/vnetpeering.bicep' = {
  name: 'peering-spoke-to-hub-deployment'
  scope: rg
  params:{
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
  params:{
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
module setNetworkContributor 'modules/roleAssignments/roleassignment.bicep' = {
  name: 'set-network-contributor'
  scope: rg
  dependsOn:[vnet, peeringSpokeToHub, peeringHubToSpoke]
  params:{
    deploymentName: 'set-network-contributor-ARM'
    principalId: servicePrincipalId
    roleDefinitionId: NetworkContributor
    targetResourceId: vnet.outputs.resourceId
  }

}
