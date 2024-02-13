param name string
param location string = resourceGroup().location
param clientId string
@secure()
param clientSecret string
param vnetName string
param masterSubnetName string
param workerSubnetName string
param clusterDomainNamePrefix string 
param tagValues object = {}


var pullSecret = loadTextContent('./pullsecret.txt')



module aro 'modules/aro/aro.bicep' = {
  name: 'aro'
  params: {
    clientId: clientId
    clientSecret: clientSecret
    location: location
    clusterName: name
    pullSecret: pullSecret
    vnetName: vnetName
    masterSubnetName: masterSubnetName
    workerSubnetName: workerSubnetName
    domainPrefix: clusterDomainNamePrefix
    tagValues: tagValues
    outboundType: 'UserDefinedRouting' 
  }
}
