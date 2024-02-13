$resourceGroupName = "rg-aro-non-prod"

az deployment group create `
--template-file ./aro-platform.bicep `
--parameters ./aro-platform.parameters.json `
--resource-group $resourceGroupName

