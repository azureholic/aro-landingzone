$location = "uksouth"
$servicePrincipalName = "aro-non-prod"



#needed for now....we cannot use a managed identity for ARO yet
#so we cannot create an identity with Bicep
$spData = az ad sp create-for-rbac `
--name $servicePrincipalName | ConvertFrom-Json

#communicate this to the aro-platform team to use for deployment of
#the aro cluster. Please keep this information safe, it will not be displayed
#again. Use Entra ID if you need to reset the Secret.
Write-Host "Client Id: " $spData.appId
Write-Host "Service Principal Secret: " $spData.password

$servicePrincipalObjectId = az ad sp show --id $spData.appId --query id

az deployment sub create `
--template-file ./azure-platform.bicep `
--parameters ./azure-platform.parameters.json `
--parameters "servicePrincipalId=$servicePrincipalObjectId" `
--location $location 

