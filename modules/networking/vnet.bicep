param location string = resourceGroup().location
param vnetName string
param vnetAddressPrefix string
param subnets array
param tagValues object = {}
param routeTableName string
param dnsServers array 

resource routeTable 'Microsoft.Network/routeTables@2023-06-01' existing = {
  name: routeTableName
}

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
    dhcpOptions: {
      dnsServers: dnsServers
    }
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.properties.addressPrefix
          privateEndpointNetworkPolicies: subnet.properties.privateEndpointNetworkPolicies
          privateLinkServiceNetworkPolicies: subnet.properties.privateLinkServiceNetworkPolicies
          routeTable: {
            id: routeTable.id
        }
      }
    }
    ]
  }
}

output name string = vnet.name  
output resourceId string = vnet.id

