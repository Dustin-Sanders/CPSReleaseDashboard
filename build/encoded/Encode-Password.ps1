$LPARS = @("CPS1","CPSA","COM2","COM3")
foreach ($LPAR in $LPARS) {
    $Password  = Read-Host "Enter your mainframe password for $($LPAR):" -AsSecureString
    
    #$Path = same as $HomePath from Set-HtmlPage.ps1
    $Path = "$PSScriptRoot"
    $Password | ConvertFrom-SecureString | Set-Content "$Path\_$LPAR.txt" -Force
}