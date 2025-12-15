#v1.0.5
#User Variables
$MainframeID      = "C204284"
#$HomePath         = "C:\Users\DuSanders\Documents\VersionDashboardTesting"
$HomePath         = "$PSScriptRoot"
$AzurePAT         = "8PfLy8rttmCQZeO7eYl1Dx8yiWflVHnQ7qLrrKYnpUzHPUOeqCPOJQQJ99BBACAAAAAiawS9AAASAZDO3htN"
$OctoApiKey       = "API-7M1JODCCUSCO1PR1DKYFHFOB9EU8FKT"

#Source Functions
Get-ChildItem "$HomePath\functions\" -Filter "*.ps1" | ForEach-Object {. $_.FullName}

#Add Release Note
$Version          = "v1.0.2"
$ReleaseNotePath  = "$($HomePath | Split-Path)\Release_Note.txt"
$Note = @"
$Version 2025/12/11
- Added release note logic.
- Added dark mode.
- Changed "jBridge" table to "Mainframe."
- Added support for CPSA, COM2 and COM3.
"@
Add-ReleaseNote -Path $ReleaseNotePath -NoteText $Note

#Retrieve Data
$EADPath          = "\\atxcpsfs01.jhapps.com\BU_SecureData\ASG\Admin\VersionDashboard\EAD\*.txt"
$ResultEAD        = Get-EADVersions -Path $EADPath
$ResultSOA        = Get-OctopusProjectVersions -ApiKey $OctoApiKey
$WorkItems        = Get-AzureWorkItems -PAT $AzurePAT
$ResultMainframe  = Get-MainframeVersions -Path $HomePath -User $MainframeID
$HtmlPath         = "$($HomePath | Split-Path)\index.html"

#Region: Define HTML Header
$HtmlHeader = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CPS Release Version Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="assets/jquery.dataTables.min.css"/>
    <link rel="icon" type="image/x-icon" href="images/favicon.png">
    <script src="assets/jquery-3.7.0.min.js"></script>
    <script src="assets/jquery.dataTables.min.js"></script>
    <script src="assets/xlsx.full.min.js"></script>
    
    <style>
        #controls {display: flex;justify-content: center;gap: 10px;margin-bottom: 20px;}
        #exportBtn {padding: 8px 16px;background: #4CAF50;color: white;border: none;border-radius: 6px;cursor: pointer;}
        #exportBtn:hover {background: #45a049;}
        #navButtons button {padding: 10px 20px;margin: 0 10px;background: #007BFF;color: white;border: none;border-radius: 6px;font-size: 14px;cursor: pointer;}
        #navButtons button:hover {background: #0056b3;}
        #navButtons {display: flex;justify-content: center;margin-bottom: 20px;}
        #rowCount {text-align: center;font-weight: bold;margin-bottom: 20px;}
        #searchInput {padding: 8px;width: 300px;border-radius: 6px;border: 1px solid #ccc;}
        .container {max-width: 1200px;margin: 40px auto;padding: 20px;background-color: #fff;border-radius: 8px;}
        .dark-mode .container {background-color: #1e1e1e;}
        .dark-mode .toggle-container {color: #ccc;}
        .dark-mode table.dataTable {border: 2px solid #5C5C5C;}
        .dark-mode tbody tr:nth-child(even) {background-color: #1e1e1e;}
        .dark-mode tbody tr:nth-child(odd) {background-color: #2a2a2a;}
        .dark-mode thead th {background-color: #333;}
        .dark-mode {background-color: #121212;color: #f4f4f4;}
        .hiddenTable {display: none;}
        .slider {position: absolute;cursor: pointer;top: 0;left: 0;right: 0;bottom: 0;background-color: #ccc;border-radius: 24px;transition: .4s;}
        .slider:before {position: absolute;content: "";height: 18px;width: 18px;left: 3px;bottom: 3px;background-color: white;border-radius: 50%;transition: .4s;}
        .toggle-container {display: flex;flex-direction: column;align-items: center;font-size: 12px;color: #777;}
        .toggle-switch input {opacity: 0;width: 0;height: 0;}
        .toggle-switch {position: relative;width: 50px;height: 24px;margin-top: 4px;}
        body.dark-mode a {color: #9E9EFF;}
        body.dark-mode a:visited {color: #D0ADF0;}
        body {font-family: Arial;background-color: #f4f4f4;color: #333;margin: 0;padding: 0;}
        footer {text-align: center;margin-top: 40px;font-size: 14px;color: #777;}
        header h1 {flex: 1;text-align: center;margin: 0;}
        header {display: flex;justify-content: space-between;align-items: center;margin-bottom: 20px;}
        input:checked + .slider {background-color: #007BFF;}
        input:checked + .slider:before {transform: translateX(26px);}
        table.dataTable {border: 2px solid #C9C9C9;width: 100%;margin: 0 auto;}
        tbody tr:nth-child(even) {background-color: #FFFFFF;}
        tbody tr:nth-child(odd) {background-color: #EDEDED;}
        thead th {background-color: #A5A5A5;color: white;}
    </style>
    
    <script>
    let currentTableId = 'soaTable';
    
    function switchTable(tableId) {
        document.getElementById('soaTable').style.display = 'none';
        document.getElementById('eadTable').style.display = 'none';
        document.getElementById('MainframeTable').style.display = 'none';
        document.getElementById(tableId).style.display = 'table';
        currentTableId = tableId;
    
        if ($.fn.dataTable.isDataTable('#' + tableId)) {
            $('#' + tableId).DataTable().destroy();
        }
        $('#' + tableId).DataTable({ paging: false, info: false, dom: 'lrtip' });
    }
    
    document.addEventListener('DOMContentLoaded', function () {
        $('#soaTable').DataTable({ paging: false, info: false, dom: 'lrtip' });
    
        document.getElementById('searchInput').addEventListener('keyup', function () {
            $('#' + currentTableId).DataTable().search(this.value).draw();
        });
    
        document.getElementById('exportBtn').addEventListener('click', function () {
            const wb = XLSX.utils.table_to_book(document.getElementById(currentTableId), { sheet: "Package Versions" });
            XLSX.writeFile(wb, 'CPSReleaseVersions_' + currentTableId + '.xlsx');
        });
    
        const toggle = document.getElementById('darkToggle');
        const savedTheme = localStorage.getItem('theme');
        if (savedTheme === 'dark') {
            document.body.classList.add('dark-mode');
            toggle.checked = true;
        }
        toggle.addEventListener('change', function () {
            if (this.checked) {
                document.body.classList.add('dark-mode');
                localStorage.setItem('theme', 'dark');
            } else {
                document.body.classList.remove('dark-mode');
                localStorage.setItem('theme', 'light');
            }
        });
    });
    </script>
</head>

'@
#End Region: Define HTML Header

#Region: Start HTML Body
$Body = @'
<body>
   <div class="container">
       <header>
           <h1>CPS Release Version Dashboard</h1>
           <div class="toggle-container">
               <span>Dark Mode</span>
               <label class="toggle-switch">
                   <input type="checkbox" id="darkToggle">
                   <span class="slider"></span>
               </label>
           </div>
       </header>
       <div id="navButtons">
           <button onclick="switchTable('soaTable')">SOA</button>
           <button onclick="switchTable('eadTable')">EAD</button>
           <button onclick="switchTable('MainframeTable')">Mainframe</button>
       </div>
       <div id="controls">
           <input type="text" id="searchInput" placeholder="Search all columns...">
           <button id="exportBtn">Export to Excel</button>
       </div>
       <div id="rowCount"></div>
       <table id="soaTable" class="display">
           <thead>
               <tr><th>Application</th><th>Environment</th><th>Package Version</th><th>Work Item URL</th></tr>
           </thead>
           <tbody>

'@
#End Region: Start HTML Body

#Region: Continue HTML Body
$HtmlRowsSOA = $ResultSOA | Sort-Object Project, Environment | ForEach-Object {
    $regex = $_.ProjectDescription
    $matchedWorkItem = $WorkItems | Where-Object {$_.Title -match $regex} | Select-Object -First 1
    $url = if ($matchedWorkItem) {
        "<a href='$($matchedWorkItem.URL)' target='_blank'>$($matchedWorkItem.ID)</a>"
    } else {
        "N/A"
    }
    "                <tr><td>$($_.Project)</td><td>$($_.Environment)</td><td>$($_.PackageVersion)</td><td>$url</td></tr>"
}

$HtmlRowsEAD = $ResultEAD | Sort-Object Component | ForEach-Object {
    "                <tr><td>$($_.Component)</td><td>$($_.Environment)</td><td>$($_.Version)</td><td>$($_.Patch)</td></tr>"
}

$HtmlRowsMainframe = $ResultMainframe | Sort-Object Component | ForEach-Object {
    "                <tr><td>$($_.Component)</td><td>$($_.Environment)</td><td>$($_.LPAR)</td><td>$($_.Version)</td></tr>"
}
#End Region: Continue HTML Body

#Region: Finish HTML Body And Set HTML Footer
$HtmlFooter = @"
        </tbody>
    </table>

    <table id="eadTable" class="display hiddenTable">
        <thead>
            <tr><th>Component</th><th>Environment</th><th>Version</th><th>Patch</th></tr>
        </thead>
        <tbody>
            $($HtmlRowsEAD -join "`n")
        </tbody>
    </table>

    <table id="MainframeTable" class="display hiddenTable">
        <thead>
            <tr><th>Component</th><th>Environment</th><th>LPAR</th><th>Version</th></tr>
        </thead>
        <tbody>
            $($HtmlRowsMainframe -join "`n")
        </tbody>
    </table>

    <footer>
        CPS Release Version Dashboard | $($Version) | Last Updated: $(Get-Date -Format 'g')
    </footer>
</div>
</body>
</html>
"@
#End Region: Finish HTML Body And Set HTML Footer

#Create web page
$HtmlContent = $HtmlHeader + $Body + ($HtmlRowsSOA -join "`n") + $HtmlFooter
Set-Content -Path $HtmlPath -Value $HtmlContent -Encoding UTF8

Write-Host "`nDone!"
Write-Host "File located here:" $HomePath | Split-Path