param targetResourceId string
param deploymentName string
param roleDefinitionId string
param principalId string
param principalType string = 'ServicePrincipal'

//disable linter warning for this construction
//in this case its correct, because there is no generic/reusable way to 
//deploy a role assignment in bicep. We'll use an ARM template for this.
#disable-next-line no-deployments-resources
resource ResourceRoleAssignment 'Microsoft.Resources/deployments@2023-07-01' = {
  name: deploymentName
  properties: {
    mode: 'Incremental'
    template: json(loadTextContent('./roleassignment.json'))
    parameters: {
      scope: {
        value: targetResourceId
      }
      roleDefinitionId: {
        value: roleDefinitionId
      }
      principalId: {
        value: principalId
      }
      principalType: {
        value: principalType
      }
      name: {
        value: guid(targetResourceId, principalId)
      }
    }
  }
}
