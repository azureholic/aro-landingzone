param name string 
param location string = resourceGroup().location
param tagValues object = {}

resource routeTable 'Microsoft.Network/routeTables@2023-09-01'={
  name: name
  location: location
  tags: tagValues
}

output routeTableName string = routeTable.name
output resourceId string = routeTable.id
