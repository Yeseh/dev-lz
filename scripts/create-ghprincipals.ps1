param (
    [string] $githubOrgOrUsername = 'yeseh',
    [string] $githubRepoName = 'dev-lz',
    [string] $tenantId
)
Import-Module Microsoft.Graph.Applications
Connect-MgGraph -Scopes "Application.ReadWrite.All" -Tenant $tenantId
Connect-AzAccount -Tenant $tenantId

$appNameBase = 'DevLandingZone-GithubActions'
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$audience = 'api://AzureADTokenExchange'
$issuer = 'https://token.actions.githubusercontent.com'
$scope = "/subscriptions/$subscriptionId"

$envs = @("dev", "prod")

# Configure service principals for each environment
foreach ($env in $envs) { 
    $appName = "$appNameBase-$env"
    $app = Get-MgApplication -Filter "displayName eq '$appName'"
    $sp = Get-MgServicePrincipal -Filter "displayName eq '$appName'"

    # Create the app and service principal if they don't exist
    if ($null -eq $app) {
        Write-Host "Creating app registration for $appName"
        New-MgApplication -DisplayName $appName | Out-Null
        Start-Sleep -Seconds 2
        $app = Get-MgApplication -Filter "displayName eq '$appName'"
        if ($null -eq $app) {
            Write-Error "Failed to create app registration for $appName"
            exit 1 
        }

        # Create a federated credential in the app registration for the github environment
        $params = ConvertTo-Json @{
            "name" = "$githubOrgOrUsername-$githubRepoName-$env"
            "issuer" = $issuer
            "subject" = "repo:$githubOrgOrUsername/$githubRepoName" + ":environment:$env"
            "audiences" = @($audience)
        } -Depth 4 

        $params | New-Item "temp.json" -Force -ItemType File | Out-Null
        Write-Host "Creating federated credential for id $($app.AppId))"
        az ad app federated-credential create --id $app.AppId --parameters temp.json 
        # Remove-Item "temp.json" | Out-Null
    }

    if ($null -eq $sp) {
        Write-Host "Creating service principal for $appName"
        New-MgServicePrincipal -BodyParameter @{ AppId = $app.AppId } | Out-Null
        Start-Sleep -Seconds 2
        $sp = Get-MgServicePrincipal -Filter "displayName eq '$appName'"
        if ($null -eq $sp) {
            Write-Error "Failed to create service principal for $appName"
            exit 1 
        }
        # Make the SP owner of the subscription, so we can also do role assignments automatically
        Write-Host "Creating role assignment for $appName. Id: $($sp.Id) Scope: $scope"
        az role assignment create --assignee-object-id $sp.Id --role Owner --scope $scope --assignee-principal-type ServicePrincipal
    }
}


