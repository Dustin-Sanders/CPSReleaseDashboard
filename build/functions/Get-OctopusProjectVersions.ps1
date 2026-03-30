#v1.0.1
function Get-OctopusProjectVersions {
    param (
        [string]$ApiKey
    )
    
    $ContentType = "application/json"
    $Headers = @{ "X-Octopus-ApiKey" = "$ApiKey" }

    $ResultSOA = @()
    $Environments = Invoke-WebRequest -Method GET -Uri "https://octopus.jhapps.com/api/Spaces-1/environments" -ContentType $ContentType -Headers $Headers | ConvertFrom-Json
    $Projects = Invoke-WebRequest -Method GET -Uri "https://octopus.jhapps.com/api/Spaces-1/projects" -ContentType $ContentType -Headers $Headers | ConvertFrom-Json

    foreach ($Project in $Projects.Items) {
        foreach ($Environment in $Environments.Items) {
            Write-Host "Retrieving info from $($Project.Name) and $($Environment.Name)."
            $DeploymentsUri = "https://octopus.jhapps.com/api/Spaces-1/deployments?projects=$($Project.Id)&environments=$($Environment.Id)&take=1"
            $DeploymentResponse = Invoke-WebRequest -Method GET -Uri $DeploymentsUri -ContentType $ContentType -Headers $Headers | ConvertFrom-Json

            if ($DeploymentResponse.Items.Count -gt 0) {
                $Deployment = $DeploymentResponse.Items[0]
                $ReleaseUri = "https://octopus.jhapps.com/api/Spaces-1/releases/$($Deployment.ReleaseId)"
                $ReleaseResponse = Invoke-WebRequest -Method GET -Uri $ReleaseUri -ContentType $ContentType -Headers $Headers | ConvertFrom-Json

                $PackageVersion = $ReleaseResponse.SelectedPackages | Select-Object -First 1

                $ResultSOA += [PSCustomObject]@{
                    Project            = $Project.Name
                    ProjectID          = $Project.Id
                    ProjectDescription = $Project.Description
                    Environment        = $Environment.Name
                    PackageVersion     = $PackageVersion.Version
                    Date               = ([datetime]$Deployment.Created).ToString("yyyy/MM/dd")
                }
            }
        }
    }

    $ResultSOA
}