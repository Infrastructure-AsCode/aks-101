<#
.SYNOPSIS
    ...
.EXAMPLE
./Create-Environment.ps1 -WorkloadName eratews -PwdBase "foo-bar-!23" -InstanceCount 2
#>
param (
    [Parameter(Mandatory = $true)]
    [string] $WorkloadName,
    [Parameter(Mandatory = $true)]
    [String] $PwdBase,
    [Parameter(Mandatory = $true)]
    [int] $InstanceCount
)

Write-Host "Provisioning shared resources"
$sharedAcrName = (az deployment sub create --location westeurope --template-file ./deploymentShared.bicep  --parameters workloadName=$workloadName --query properties.outputs.acrName.value)

for ($i = 1; $i -le $InstanceCount; $i++) {
    $userName = "$workloadName-user$i"
    $principalName = "$userName@iac-labs.com"

    Write-Host "Create new AD user $userName"
    az ad user create --display-name $userName --password "$PwdBase$i" --user-principal-name $principalName --force-change-password-next-sign-in false
    
    Write-Host "Provisioning AKS instance $i "
    az deployment sub create --location westeurope --template-file ./deployment.bicep  --parameters workloadName=$workloadName instanceId=$i sharedAcrName=$sharedAcrName

    $rgId = (az group show -n $workloadName-rg-$i --query id)
    Write-Host "Assign Contributor role to $principalName at $rdId scope"
    az role assignment create --role "Contributor" --assignee $principalName --scope $rgId
}
