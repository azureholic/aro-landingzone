param location string = resourceGroup().location
param vnetName string
param vnetAddressPrefix string
param subnets array
param tagValues object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: vnetName
  location: location
  tags: tagValues
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: subnets
  }
}

output name string = vnet.name  
output resourceId string = vnet.id

