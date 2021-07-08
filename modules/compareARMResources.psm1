function Compare-ARM {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String] $resourceGroup,
        [Parameter()]
        [String] $sourceApimName,
        [Parameter()]
        [String] $destinationApimName,
        [Parameter()]
        [boolean] $openCodeForCompare
    )

    Remove-Item -Path ".\compare" -Force -Recurse

    New-Item -ItemType Directory -Path ".\compare" -Force

    $destinationApimId = (az resource show --resource-group $resourceGroup --name $destinationApimName --resource-type Microsoft.ApiManagement/service --query id --output tsv)
    $sourceApimId = (az resource show --resource-group $resourceGroup --name $sourceApimName --resource-type Microsoft.ApiManagement/service --query id --output tsv)

    az group export --resource-group $resourceGroup --resource-ids $destinationApimId | Out-File -FilePath ".\compare\$destinationApimName.json" 
    az group export --resource-group $resourceGroup --resource-ids $sourceApimId | Out-File -FilePath ".\compare\$sourceApimName.json" 

    (Get-Content ".\compare\$destinationApimName.json") `
        -replace "($destinationApimName)", "$sourceApimName" |
    Out-File ".\compare\$destinationApimName-compare.json"

    $sourceTemplate = Get-Content ".\compare\$sourceApimName.json" | ConvertFrom-Json
    $untrackedResources = @("Microsoft.ApiManagement/service/subscriptions", `
    "Microsoft.ApiManagement/service/users", `
    "Microsoft.ApiManagement/service/groups/users", `
    "Microsoft.ApiManagement/service/groups", `
    "Microsoft.ApiManagement/service")
    $sourceTemplateResources = $sourceTemplate.resources | Where-Object { $_.type -notin $untrackedResources}

    $sourceProps = $sourceTemplate.parameters.PSObject.properties | Where-Object {$_.name -like "subscription*" }
    $sourceProps | ForEach-Object { $sourceTemplate.parameters.PSObject.properties.remove($_.name) }  

    $sourceTemplate.resources = $sourceTemplateResources
    $sourceTemplate | ConvertTo-Json -Depth 32 | Out-File -FilePath ".\compare\$sourceApimName-compare.json" 

    $destinationTemplate = Get-Content ".\compare\$destinationApimName-compare.json" | ConvertFrom-Json
    $destinationTemplateResources = $destinationTemplate.resources | Where-Object { $_.type -notin $untrackedResources}

    $destinationProps = $destinationTemplate.parameters.PSObject.properties | Where-Object {$_.name -like "subscription*" }
    $destinationProps | ForEach-Object { $destinationTemplate.parameters.PSObject.properties.remove($_.name) }  

    $destinationTemplate.resources = $destinationTemplateResources
    $destinationTemplate | ConvertTo-Json -Depth 32 | Out-File -FilePath ".\compare\$destinationApimName-compare.json" 

    if($openCodeForCompare)
    {
        #This will open vscode and compare the 2 normalised template files for differences
        code --diff ".\compare\$sourceApimName-compare.json" ".\compare\$destinationApimName-compare.json"
    }
    
}

Export-ModuleMember -Function Compare-ARM