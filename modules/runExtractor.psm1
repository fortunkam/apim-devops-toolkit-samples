Import-Module -Name "$PSScriptRoot\cleanup-Apim.psm1"
Import-Module -Name "$PSScriptRoot\compareARMResources.psm1"

$resourceGroup="apim-kv-pl"
$sourceApimName="mfapim"
$destinationApimName="mfapim2"

function Run-ExtractorWorkflow {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String] $resourceGroup,
        [Parameter()]
        [String] $sourceApimName,
        [Parameter()]
        [String] $destinationApimName,
        [Parameter()]
        [array] $keyVaultNamedValuesToBeRemoved,
        [Parameter()]
        [object] $namedValueParameters,
        [Parameter()]
        [String] $blobAccount,
        [Parameter()]
        [String] $blobContainer,
        [Parameter()]
        [String] $extractorConfigFile,
        [Parameter()]
        [String] $extractProjectPath,
        [Parameter()]
        [String] $baseFileName

    )

    Reset-APIM -resourceGroup $resourceGroup -apimName $destinationApimName -keyVaultNamedValues $keyVaultNamedValuesToBeRemoved

    # Clean up the templates folder

    Remove-Item -Path ".\templates" -Force -Recurse
    New-Item -ItemType Directory -Path ".\templates" -Force

    #Run the extractor tool
    dotnet run extract --extractorConfig $extractorConfigFile `
        --baseFileName $baseFileName `
        -p "$extractProjectPath\apimtemplate.csproj" -c "Release"


    # Update files to blob storage 

    $templateVersion=Get-Date -Format "yyyyMMddHHmmss"
    $templateFolder="./templates"
    $deploymentName="deploy$templateVersion"

    $accountKey = (az storage account keys list --account-name $blobAccount --query [0].value -o tsv)

    az storage blob upload-batch -d $blobContainer --account-name $blobAccount --account-key $accountKey -s $templateFolder --pattern *.* --destination-path $templateVersion

    $namedValuesJson = ($namedValueParameters | ConvertTo-Json -Depth 30 -Compress).Replace('"', '\"')
    $linkedTemplatesBaseUrl = "https://$blobAccount.blob.core.windows.net/$blobContainer/$templateVersion"
    $policyBaseUrl = "https://$blobAccount.blob.core.windows.net/$blobContainer/$templateVersion/policies"

    az deployment group create --resource-group $resourceGroup --name $deploymentName `
        --template-file "./templates/$baseFileName-master.template.json"  `
        --parameters "./templates/$baseFileName-parameters.json" `
        --parameters LinkedTemplatesBaseUrl=$linkedTemplatesBaseUrl `
        --parameters PolicyXMLBaseUrl=$policyBaseUrl `
        --parameters NamedValues=$namedValuesJson

    # Export the templates for each for compare.

    Compare-ARM -resourceGroup $resourceGroup -destinationApimName $destinationApimName -sourceApimName $sourceApimName -openCodeForCompare $true

}
Export-ModuleMember -Function Run-ExtractorWorkflow