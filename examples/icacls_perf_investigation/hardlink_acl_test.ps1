param(
    [string]$SourceFile = "$env:SystemRoot\System32\cmd.exe",
    [string]$SameVolumeDir = "$env:SystemDrive\icacls_test_same_volume",
    [string]$OtherVolumeDir = $null
)

function Test-Hardlink($TargetDir, $Label) {
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    $link = Join-Path $TargetDir "linked.exe"
    Remove-Item $link -ErrorAction SilentlyContinue
    cmd /c mklink /H "$link" "$SourceFile" | Out-Null
    Write-Host "=== $Label ($link) ==="
    icacls $link
    Write-Host ""
}

Write-Host "Running as: $(whoami)"
Write-Host "Source file: $SourceFile"
Write-Host ""

Test-Hardlink -TargetDir $SameVolumeDir -Label "Same volume as source ($SameVolumeDir)"

if ($OtherVolumeDir) {
    Test-Hardlink -TargetDir $OtherVolumeDir -Label "Different volume from source ($OtherVolumeDir)"
} else {
    Write-Host "No -OtherVolumeDir supplied; skipping cross-volume comparison."
}
