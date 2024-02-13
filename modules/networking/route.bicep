param routeTableName string
param routeName string
param addressPrefix string

@allowed([
  'VirtualAppliance'
  'VnetLocal'
  'Internet'
  'VirtualNetworkGateway'
  'None'
])

param nextHopType string
param nextHopIpAddress string

resource routeTable 'Microsoft.Network/routeTables@2023-09-01' existing = {
  name: routeTableName
}


resource route 'Microsoft.Network/routeTables/routes@2023-09-01' = {
  name: routeName
  parent: routeTable
  properties: {
    addressPrefix: addressPrefix
    nextHopType: nextHopType
    nextHopIpAddress: nextHopIpAddress
    
  }
}
