function Add-ReleaseNote {
    param(
        [string]$Path,
        [string]$NoteText
    )

    # Compute SHA-256 signature for idempotency
    $Normalized = ($NoteText -replace '\r\n?', "`n").Trim()
    $Sha = [System.Security.Cryptography.SHA256]::Create()
    $Bytes = [Text.Encoding]::UTF8.GetBytes($Normalized)
    $Hash = ($Sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
    $Sha.Dispose()
    $Signature = "RN-SHA256:$Hash"

    # Read existing file if present
    $Existing = if (Test-Path $Path) { Get-Content $Path -Raw } else { $null }

    # Skip if note already exists
    if ($Existing -and $Existing.Contains($Signature)) {
        Write-Host "Skipped: release note already present`n"
        return
    }

    #Prepend the note, append the signature and a new row
    $NoteBlock = $NoteText.TrimEnd() + "`r`n" + "#$Signature#" + "`r`n`r`n"
    $NewContent = if ($Existing) { $NoteBlock + $Existing } else { $NoteBlock }

    Set-Content $Path $NewContent
    Write-Host "Release note added to $Path`n"
}