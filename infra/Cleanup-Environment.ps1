<#
.SYNOPSIS
    ...
.EXAMPLE
./Cleanup-Environment.ps1 -WorkloadName eratews -InstanceCount 2
#>
param (
    [Parameter(Mandatory = $true)]
    [string] $WorkloadName,
    [Parameter(Mandatory = $true)]
    [int] $InstanceCount
)

for ($i = 2; $i -le $InstanceCount; $i++) {
    $userName = "$workloadName-user$i"
    $principalName = "$userName@iac-labs.com"
    $rgName = "$workloadName-rg-$i"

    Write-Host "Deleting resource group $rgName..."
    az group delete -n $rgName -y   

    Write-Host "Deleting AD user $userName..."
    az ad user delete --id $principalName
}

$rgName = "$workloadName-rg"
az group delete -n $rgName -y   