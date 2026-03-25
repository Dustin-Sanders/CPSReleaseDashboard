#Run in the jhapps.com admin VDI

function Get-EADVersions { 
    $Servers = @(
    "ATXCPSEADAPP2",
    "ATXCPSEADBOLG2",
    "ATXCPSEADQAPP2",
    "ATXCPSEADAQBOLG2",
    "BMOCPSEADAPP2",
    "BMOCPSEADBOLG2"
    )

    foreach ($Server in $Servers) {
        $D = "\\ATXCPSFS01.jhapps.com\BU_SecureData\ASG\Admin\VersionDashboard\EAD\$Server\"
    
        if (-not (Test-Path -Path $D)) {
            New-Item -ItemType Directory -Path $D -Force | Out-Null
        }
    
        Write-Host "Copying files from $Server."
        Get-ChildItem "\\$Server\F$\vers" -Exclude "ver*com*" |
        Copy-Item -Destination $D -ErrorAction Stop -Force
    }
}