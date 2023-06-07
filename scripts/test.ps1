$output = $(az devcenter dev environment show --dev-center dc-devlz --project project-devlz --name test | ConvertFrom-Json)
if ($null -eq $output) {
    Write-Host "No environment found"
} else {
    Write-Host "Environment found"
}