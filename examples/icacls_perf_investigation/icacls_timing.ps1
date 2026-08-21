param(
    [string]$TargetDir = "$env:SystemDrive\icacls_timing_test",
    [int[]]$FileCounts = @(1000, 10000, 50000, 150000),
    [switch]$Recreate
)

$defender = Get-MpPreference -ErrorAction SilentlyContinue
if ($defender) {
    Write-Host "Defender real-time protection disabled: $($defender.DisableRealtimeMonitoring)"
    Write-Host "Exclusion paths: $($defender.ExclusionPath -join ', ')"
} else {
    Write-Host "Could not query Defender preferences (Get-MpPreference)."
}
Write-Host ""

if ($Recreate -and (Test-Path $TargetDir)) {
    Remove-Item -Recurse -Force $TargetDir
}
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

$existing = 0
$prevCount = 0
foreach ($count in $FileCounts | Sort-Object) {
    $toCreate = $count - $prevCount
    for ($i = $prevCount; $i -lt $count; $i++) {
        $sub = Join-Path $TargetDir ("dir_" + [math]::Floor($i / 1000))
        New-Item -ItemType Directory -Force -Path $sub | Out-Null
        Set-Content -Path (Join-Path $sub "file_$i.txt") -Value "x"
    }
    $prevCount = $count

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    icacls "$TargetDir\*" /inheritance:e /T /C /Q | Out-Null
    $sw.Stop()
    Write-Host "$count files: icacls /inheritance:e /T /C /Q took $($sw.Elapsed.TotalSeconds) s"
}
