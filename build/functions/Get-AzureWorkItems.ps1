#v1.0.1
function Get-AzureWorkItems {
    param (
        [string]$PAT,
        [string[]]$Teams = @("CPS Development Team"),
        [string[]]$Types = @("In Production")
    )

    $Header = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
    $WorkItems = @()

    foreach ($Team in $Teams.Replace(' ', '%20')) {
        $ProjectUri = "https://dev.azure.com/JHA-3/PassPortEFT/$Team"
        $Uri = "$ProjectUri/_apis/wit/wiql?api-version=6.0"

        foreach ($Type in $Types) {
            Write-Host "Retrieving info from $Uri"
            if ($Team -like "*Development*") {
                $Body = @{
                    "Query" = "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [WEF_B551117A5D9E4258A3CE57F6764452CD_Kanban.Column] = '$Type'"
                } | ConvertTo-Json
            }

            $Result = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Header -Body $Body -ContentType 'application/json'

            if ($Result.workItems.Count -gt 0) {
                $IdsArray = $Result.workItems | ForEach-Object { $_.id }
                $Ids = $IdsArray -join ","
                $DetailsUri = "https://dev.azure.com/JHA-3/PassPortEFT/_apis/wit/workitems?ids=$($Ids)&fields=System.Id,System.Title&api-version=6.0"
                $Details = Invoke-RestMethod -Uri $DetailsUri -Headers $Header

                $Details.value | ForEach-Object {
                    $WorkItems += [PSCustomObject]@{
                        ID    = $_.fields.'System.Id'
                        Title = $_.fields.'System.Title'
                        URL   = "https://dev.azure.com/JHA-3/PassPortEFT/_workitems/edit/$($_.fields.'System.Id')"
                        API   = "https://dev.azure.com/JHA-3/e3b19aed-08ad-4f99-84a8-dd6acb97beb7/_apis/wit/workItems/$($_.fields.'System.Id')?`$expand=all"
                    }
                }
            }
        }
    }

    $WorkItems
}