#v1.0.2
function Get-MainframeVersions {
    param (
        [string]$Path,
        [string]$User
    )
    
    $Targets = @(
        @{Host='cps1.mainframe.jhapps.com'; LPAR='CPS1'; ScriptPath='/xlp/admin/asg/scripts/miscellaneous/get-dashboardjson.sh'}
        @{Host='cpsa.mainframe.jhapps.com'; LPAR='CPSA'; ScriptPath='/opt/cpsapp/asg/scripts/get-dashboardjson.sh'}
        @{Host='com2.mainframe.jhapps.com'; LPAR='COM2'; ScriptPath='/opt/cpsapp/asg/scripts/get-dashboardjson.sh'},
        @{Host='com3.mainframe.jhapps.com'; LPAR='COM3'; ScriptPath='/opt/cpsapp/asg/scripts/get-dashboardjson.sh'}
    )


    $ResultMainframe = @()

    foreach ($T in $Targets) {
        $Password = Get-Content -LiteralPath "$Path\encoded\_$($T.LPAR).txt" | ConvertTo-SecureString
        $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
        Write-Host "Retrieving info from $($T.Host)."
        $Output = & 'C:\Program Files\PuTTY\plink.exe' -batch -ssh $T.Host -l $User -pw $Password $T.ScriptPath
        $JSON = $Output | ConvertFrom-Json
        foreach ($Application in $JSON.Applications) {
            $ResultMainframe += [PSCustomObject]@{
                Component   = $Application.Component
                Environment = $Application.Environment
                LPAR        = $T.LPAR
                Version     = $Application.Version
            }
        }
    }
    
    $ResultMainframe
}

