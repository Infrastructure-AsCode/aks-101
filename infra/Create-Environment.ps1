<#
.SYNOPSIS
    ...
.EXAMPLE
./Create-Environment.ps1 -WorkloadName eratews-user -PasswordBase "foo-bar-!23" -InstanceCount 2
#>
param (
    [Parameter(Mandatory = $true)]
    [string] $WorkloadName,
    [Parameter(Mandatory = $true)]
    [SecureString] $PasswordBase,
    [Parameter(Mandatory = $true)]
    [int] $InstanceCount
)

for ($i = 1; $i -le $InstanceCount; $i++) {
    $userName = "$workloadName$i"
    $principalName = "$userName@iac-labs.com"
    
    Write-Host "Provisioning AKS instance for user$i "
    az deployment sub create --location westeurope --template-file ./deployment.bicep  --parameters workloadName=$workloadName instanceId=$i   

    Write-Host "Create new AD user $userName"
    az ad user create --display-name $userName --password "$PasswordBase$i" --user-principal-name $principalName --force-change-password-next-sign-in false
 
    $rgId = (az group show -n $workloadName$i-rg --query id)
    Write-Host "Assign Contributor role to $principalName at $rdId scope"
    az role assignment create --role "Contributor" --assignee $principalName --scope $rgId
}