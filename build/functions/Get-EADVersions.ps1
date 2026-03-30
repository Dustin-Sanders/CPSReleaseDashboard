#v1.0.3
function Get-EADVersions {
    param (
        #[string]$Path = "\\ATXCPSFS01.jhapps.com\BU_SecureData\ASG\Admin\VersionDashboard\EAD",
        [string]$Path,
        [string]$ExcludeFile = "Version Commands.txt"
    )

    Get-ChildItem -Path $Path -Exclude $ExcludeFile -File -Recurse | ForEach-Object {
        Write-Host "Retrieving info from EAD patch file $($_.Name)."

        $FolderName  = Split-Path $_.DirectoryName -Leaf
        $Datacenter  = $FolderName.Substring(0,3)
        $Environment = 'Production'
        $App         = 'APP'

        switch -Regex ($FolderName) {
            'QA'  { $Environment = 'QA' }
            'BO'  { $App = 'BO' }
        }

        $Content = Get-Content -Path $_.FullName -TotalCount 2
        $Version = if ($Content.Count -ge 2 -and $Content[1] -match '\S') {
            ($Content[1] -replace '[()]','').Trim()
        } else { 'N/A' }

        $Match = Select-String -Path $_.FullName -Pattern 'Patch\d{3}\s([^:]+)' | Select-Object -Last 1
        $Patch = if ($Match) { $Match.Matches[0].Value } else { 'N/A' }

        #[PSCustomObject]@{
        #    Component   = (Get-Culture).TextInfo.ToTitleCase($_.BaseName.Split('_')[0])
        #    Environment = $Environment
        #    Version     = $Version
        #    Patch       = $Patch
        #}
        
       [PSCustomObject]@{
            Component   = (Get-Culture).TextInfo.ToTitleCase($_.BaseName.Split('_')[0])
            Datacenter  = $Datacenter
            App         = $App
            Environment = $Environment
            Version     = -join $Version[0..20]
            Patch       = $Patch
        }
    }
}