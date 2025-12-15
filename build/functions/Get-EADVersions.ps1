#v1.0.2
function Get-EADVersions {
    param (
        [string]$Path,
        [string]$ExcludeFile = "Version Commands.txt",
        [string]$Environment = "Production"
    )


    Get-ChildItem -Path $Path -Exclude $ExcludeFile -File | ForEach-Object {
        Write-Host "Retrieving info from EAD patch file $($_.Name)."
        $Content = Get-Content -Path $_.FullName -TotalCount 2
        $Version = if ($Content.Count -ge 2 -and $Content[1] -match '\S') {
            ($Content[1] -replace '[()]','').Trim()
        } else { 'N/A' }

        #Find the patch
        $Match = Select-String -Path $_.FullName -Pattern 'Patch\d{3}\s([^:]+)' | Select-Object -Last 1
        $Patch = if ($Match) { $Match.Matches[0].Value } else { 'N/A' }

        [PSCustomObject]@{
            Component   = (Get-Culture).TextInfo.ToTitleCase($_.BaseName.Split('_')[0])
            Environment = $Environment
            Version     = $Version
            Patch       = $Patch
        }
    }
}