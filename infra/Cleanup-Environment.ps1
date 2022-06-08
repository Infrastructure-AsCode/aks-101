<#
.SYNOPSIS
    ...
.EXAMPLE
./Cleanup-Environment.ps1 -WorkloadName eratews-user -InstanceCount 2
#>
param (
    [Parameter(Mandatory = $true)]
    [string] $WorkloadName,
    [Parameter(Mandatory = $true)]
    [int] $InstanceCount
)

for ($i = 3; $i -le $InstanceCount; $i++) {
    $userName = "$workloadName$i"
    $principalName = "$userName@iac-labs.com"
    $rgName = "$workloadName$i-rg"

    Write-Host "Deleting resource group $rgName..."
    az group delete -n $rgName -y   

    Write-Host "Deleting AD user $userName..."
    az ad user delete --id $principalName
}