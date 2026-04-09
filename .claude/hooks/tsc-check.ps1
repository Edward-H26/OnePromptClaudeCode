$ErrorActionPreference = "Stop"

$hookInput = [Console]::In.ReadToEnd()
$data = $hookInput | ConvertFrom-Json

$toolName = $data.tool_name
if ($toolName -notin @("Edit", "MultiEdit", "Write")) { exit 0 }

. "$PSScriptRoot/lib/utils.ps1"

$claudeHome = Resolve-ClaudeHome
$rawSessionId = if ($data.session_id) { $data.session_id } else { "default" }
$sessionId = $rawSessionId -replace "[^a-zA-Z0-9_-]", ""
if (-not $sessionId) { $sessionId = "default" }
$cacheDir = Join-Path $claudeHome "tsc-cache/$sessionId"

New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null

$affectedReposFile = Join-Path $cacheDir "affected-repos.txt"
$reposToCheck = @()

if (Test-Path $affectedReposFile) {
    $reposToCheck = Get-Content $affectedReposFile | Sort-Object -Unique
} else {
    $toolInput = $data.tool_input
    $filePaths = @()
    if ($toolName -eq "MultiEdit") {
        $filePaths = $toolInput.edits | ForEach-Object { $_.file_path }
    } else {
        $filePaths = @($toolInput.file_path)
    }
    foreach ($fp in $filePaths) {
        if ($fp -match "\.(ts|tsx|js|jsx)$") {
            $repo = Get-RepoForFile -FilePath $fp
            if ($repo) { $reposToCheck += $repo }
        }
    }
    $reposToCheck = $reposToCheck | Sort-Object -Unique
}

if ($reposToCheck.Count -eq 0) { exit 0 }

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { Get-Location }
$errorCount = 0
$errorOutput = ""
$failedRepos = @()

Write-Host "TypeScript check on: $($reposToCheck -join ' ')" -ForegroundColor Cyan

foreach ($repo in $reposToCheck) {
    if (-not $repo) { continue }
    $repoPath = Join-Path $projectDir $repo
    Write-Host "  Checking $repo... " -NoNewline

    $tscCmd = Get-TscCommand -RepoPath $repoPath
    if (-not $tscCmd) {
        Write-Host "Skipped" -ForegroundColor Yellow
        continue
    }

    if (-not (Test-TscCommand $tscCmd)) {
        Write-Host "Skipped (unsafe command)" -ForegroundColor Yellow
        continue
    }

    $pushed = $false
    try {
        Push-Location $repoPath
        $pushed = $true
        $tscArgs = $tscCmd -split "\s+"
        $output = & $tscArgs[0] $tscArgs[1..($tscArgs.Length-1)] 2>&1
        $exitCode = $LASTEXITCODE
    } catch {
        $exitCode = 1
        $output = $_.Exception.Message
    } finally {
        if ($pushed) { Pop-Location }
    }

    if ($exitCode -ne 0) {
        Write-Host "Errors found" -ForegroundColor Red
        $errorCount++
        $failedRepos += $repo
        $errorOutput += "`n=== Errors in $repo ===`n$output"
    } else {
        Write-Host "OK" -ForegroundColor Green
    }
}

if ($errorCount -gt 0) {
    $errorOutput | Set-Content (Join-Path $cacheDir "last-errors.txt")
    $failedRepos | Set-Content $affectedReposFile

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "TypeScript errors found in $errorCount repo(s): $($failedRepos -join ' ')" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    Write-Host "IMPORTANT: Use the auto-error-resolver agent to fix the errors" -ForegroundColor Yellow
    exit 1
}

exit 0
