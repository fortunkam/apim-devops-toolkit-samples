Import-Module -Name "$PSScriptRoot\..\..\modules\runExtractor.psm1" -Force

$resourceGroup="apim-kv-pl"
$sourceApimName="mfapim"
$destinationApimName="mfapim2"
$blobAccount="mfapimdevportal"
$container="arm-test"

$namedValues = @{
    "KVSecret1a"= "This is a secret value"
    "KVSecret2a"= "This is a secret value 2"
    "KVSecret3"= "This is a secret value 3"
    "KVSecret4"= "This is a secret value 4"
    "Property60c38cad4ce5721780d17985"= "caa8f0b0-34cf-48d0-a2fc-f39379313ffa"
    "Property60e078d14ce5720a942b9ff0"= "Endpoint=sb://mfapimeventhub.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=NZT1s2L7LyXLPIh9qFS+Jb6lFUvJyXBSQc43jb3dGTk="
    "mfsimplefunctionkey"= "jgU0tCVx9++JaNy+Ndnsr6V89R1iXdk683PBReW5kqbbmeda4fo0Rg=="
}

$namedValuesToBeRemoved = @("Test1", "Test2")

Run-ExtractorWorkflow -resourceGroup $resourceGroup `
    -sourceApimName $sourceApimName `
    -destinationApimName $destinationApimName `
    -keyVaultNamedValuesToBeRemoved $namedValuesToBeRemoved `
    -namedValueParameters $namedValues `
    -blobAccount $blobAccount `
    -blobContainer $container `
    -extractorConfigFile ".\apim-extractor-config.json" `
    -extractProjectPath "C:\dev\apim\azure-api-management-devops-resource-kit\src\APIM_ARMTemplate\apimtemplate\" `
    -baseFileName "mf"
