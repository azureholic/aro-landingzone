@description('virtual network name for the cluster')
param vnetName string 

@description('subnet name for the master nodes')
param masterSubnetName string 

@description('subnet name for the worker nodes')
param workerSubnetName string 

@description('Location')
param location string = resourceGroup().location

@description('Domain Prefix')
param domainPrefix string = ''

@description('Pull secret from cloud.redhat.com. The json should be input as a string')
@secure()
param pullSecret string

//supported VM Sizes for Master
//https://learn.microsoft.com/en-us/azure/openshift/support-policies-v4#control-plane-nodes
@description('Master Node VM Type')
param masterVmSize string = 'Standard_D8s_v3'

//https://learn.microsoft.com/en-us/azure/openshift/support-policies-v4#worker-nodes
//param workerVmSize string = 'Standard_D4s_v3'
@description('Worker Node VM Type')
param workerVmSize string = 'Standard_D4s_v3'

@description('Worker Node Disk Size in GB')
@minValue(128)
param workerVmDiskSize int = 128

@description('Number of Worker Nodes')
@minValue(3)
param workerCount int = 3

@description('Cidr for Pods')
param podCidr string = '10.128.0.0/14'

@metadata({
  description: 'Cidr of service'
})
param serviceCidr string = '172.30.0.0/16'

@description('Unique name for the cluster')
param clusterName string

@description('Tags for resources')
param tagValues object = {}


@description('Api Server Visibility')
@allowed([
  'Private'
  'Public'
])
param apiServerVisibility string = 'Private'

@description('Ingress Visibility')
@allowed([
  'Private'
  'Public'
])
param ingressVisibility string = 'Private'

@description('Outbound Type - UserDefinedRouting for Azure Firewall or LoadBalancer for Standard Load Balancer')
@allowed([
  'UserDefinedRouting'
  'LoadBalancer'
])
param outboundType string

@description('The Application ID of an Azure Active Directory client application')
param clientId string

@description('The secret of an Azure Active Directory client application')
@secure()
param clientSecret string


@description('Specify if FIPS validated crypto modules are used')
@allowed([
  'Enabled'
  'Disabled'
])
param fips string = 'Disabled'

@description('Specify if master VMs are encrypted at host')
@allowed([
  'Enabled'
  'Disabled'
])
param masterEncryptionAtHost string = 'Disabled'

@description('Specify if worker VMs are encrypted at host')
@allowed([
  'Enabled'
  'Disabled'
])
param workerEncryptionAtHost string = 'Disabled'

@description('The resource group name for managed resources of the cluster. If not provided, a default name will be used.')
param clusterResourcesResourceGroupName string = ''

var rgName = clusterResourcesResourceGroupName == '' ? 'aro-${domainPrefix}-${location}-rg' : clusterResourcesResourceGroupName
var resourceGroupId = subscriptionResourceId('Microsoft.Resources/resourceGroups', rgName)

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

resource masterSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: masterSubnetName
  parent: vnet
}

resource workerSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01'  existing  =  {
  name: workerSubnetName
  parent: vnet
}


resource clusterName_resource 'Microsoft.RedHatOpenShift/OpenShiftClusters@2023-04-01' = {
  name: clusterName
  location: location
  tags: tagValues
  properties: {
    clusterProfile: {
      domain: domainPrefix 
      resourceGroupId: resourceGroupId
      pullSecret: pullSecret
      fipsValidatedModules: fips
    }
    networkProfile: {
      podCidr: podCidr
      serviceCidr: serviceCidr
      outboundType: outboundType
    }
    servicePrincipalProfile: {
      clientId: clientId
      clientSecret: clientSecret
    }
    masterProfile: {
      vmSize: masterVmSize
      subnetId: masterSubnet.id
      encryptionAtHost: masterEncryptionAtHost
    }
    workerProfiles: [
      {
        name: 'worker'
        vmSize: workerVmSize
        diskSizeGB: workerVmDiskSize
        subnetId: workerSubnet.id
        count: workerCount
        encryptionAtHost: workerEncryptionAtHost
      }
    ]
    apiserverProfile: {
      visibility: apiServerVisibility
    }
    ingressProfiles: [
      {
        name: 'default'
        visibility: ingressVisibility
      }
    ]
  }
}
