Import-Module -Name "$PSScriptRoot\..\..\modules\cleanup-Apim.psm1"

$resourceGroup="apim-kv-pl"
$destinationApimName="mfapim2"

Reset-APIM -resourceGroup $resourceGroup `
     -apimName $destinationApimName `
     -keyVaultNamedValues @("Test1", "Test2")

# Clean up the templates folder

Remove-Item -Path ".\templates" -Force -Recurse
New-Item -ItemType Directory -Path ".\templates" -Force

$extractProjectPath = "C:\dev\apim\azure-api-management-devops-resource-kit\src\APIM_ARMTemplate\apimtemplate\"
dotnet run create --configFile creator.yml -p "$extractProjectPath\apimtemplate.csproj" -c "Release"

$templateVersion=Get-Date -Format "yyyyMMddHHmmss"
$templateFolder="./templates"
$deploymentName="deploy$templateVersion"
$apiName = "testingautomation1"
$apiServiceUrl = "http://httpbin.org"

Write-Host "Deploying api version set"
az deployment group create --resource-group $resourceGroup --name $deploymentName `
        --template-file "$templateFolder/$destinationApimName-apiVersionSets.template.json"  `
        --parameters ApimServiceName=$destinationApimName

Write-Host "Deploying named values"
az deployment group create --resource-group $resourceGroup --name $deploymentName `
        --template-file "$templateFolder/$destinationApimName-namedValues.template.json"  `
        --parameters ApimServiceName=$destinationApimName

Write-Host "Deploying api $apiName-initial"
az deployment group create --resource-group $resourceGroup --name $deploymentName `
        --template-file "$templateFolder/$apiName-initial.api.template.json"  `
        --parameters ApimServiceName=$destinationApimName `
        --parameters "$apiName-ServiceUrl=$apiServiceUrl"

Write-Host "Deploying api $apiName-subsequent"
az deployment group create --resource-group $resourceGroup --name $deploymentName `
        --template-file "$templateFolder/$apiName-subsequent.api.template.json"  `
        --parameters ApimServiceName=$destinationApimName `
        --parameters "$apiName-ServiceUrl=$apiServiceUrl"