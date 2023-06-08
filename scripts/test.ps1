$branch = 'feature/test-wf'
$envName = $branch.Replace("-", "").Replace("/", "-")
$slug = $envName.Replace("feature-", "")
$data = @{"slug" = "$slug" } | ConvertTo-Json -Depth 2
$params = $data.replace('"', '""').replace("`n", '')
$existing = $(az devcenter dev environment show --dev-center dc-devlz --project project-devlz --name $envName | ConvertFrom-Json)
if ($null -eq $existing) {
    Write-Host "Environment for branch $branch not found, creating..."
    az devcenter dev environment create --catalog-name Catalog-devlz --environment-type dev --parameters "$params" --dev-center dc-devlz --project project-devlz --environment-definition-name dotnet-function-app --name $envName
} else {
    Write-Host "Environment for branch $branch already exists..."
}
