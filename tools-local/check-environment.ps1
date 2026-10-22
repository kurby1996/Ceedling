# Read-only prerequisite check. Does not install software or change PATH.
$ErrorActionPreference = 'Stop'
$missing = @()
foreach ($name in @('git', 'ruby', 'gem', 'gcc', 'ceedling')) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        Write-Output "MISSING: $name (not found on current PATH)"
        $missing += $name
        continue
    }
    Write-Output "FOUND: $name => $($command.Source)"
    if ($name -eq 'ceedling') {
        & $command.Source version
    } else {
        & $command.Source --version
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Output "FAILED: $name returned $LASTEXITCODE"
        $missing += $name
    }
}
if ($missing.Count -gt 0) {
    Write-Output ('Environment not ready: ' + ($missing -join ', '))
    exit 1
}
Write-Output 'Commands are available. Run an actual Ceedling test project to validate compilation and execution.'
exit 0
