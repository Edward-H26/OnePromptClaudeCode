function Resolve-ClaudeHome {
    $scriptDir = Split-Path -Parent $PSScriptRoot
    $candidate = $scriptDir
    while ($candidate -ne [System.IO.Path]::GetPathRoot($candidate)) {
        if ((Test-Path "$candidate/hooks") -and (Test-Path "$candidate/skills")) {
            return $candidate
        }
        $candidate = Split-Path -Parent $candidate
    }
    $homeClaude = Join-Path $HOME ".claude"
    if (Test-Path $homeClaude) {
        return (Resolve-Path $homeClaude).Path
    }
    return ""
}

function Get-RepoCacheKey {
    param([string]$Repo = ".")
    $normalized = if ($Repo -eq ".") { "root" } else { $Repo }
    $safeName = $normalized -replace "[/\\]", "_" -replace "[^a-zA-Z0-9_.-]", "_"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Repo)
    $hash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace("-","").Substring(0,8)
    return "${safeName}-${hash}"
}

function Get-RepoForFile {
    param([string]$FilePath)
    $projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { Get-Location }
    $relativePath = $FilePath.Replace("$projectDir/", "").Replace("$projectDir\", "")
    $dirPath = Split-Path -Parent $relativePath
    while ($dirPath -and $dirPath -ne ".") {
        $fullPath = Join-Path $projectDir $dirPath
        if ((Test-Path "$fullPath/package.json") -or
            (Test-Path "$fullPath/tsconfig.json") -or
            (Test-Path "$fullPath/.git")) {
            return $dirPath
        }
        $dirPath = Split-Path -Parent $dirPath
    }
    if ((Test-Path "$projectDir/package.json") -or (Test-Path "$projectDir/.git")) {
        return "."
    }
    return ""
}

function Get-TscCommand {
    param([string]$RepoPath)
    if (Test-Path "$RepoPath/tsconfig.app.json") {
        return "npx tsc --project tsconfig.app.json --noEmit"
    } elseif (Test-Path "$RepoPath/tsconfig.build.json") {
        return "npx tsc --project tsconfig.build.json --noEmit"
    } elseif (Test-Path "$RepoPath/tsconfig.json") {
        $content = Get-Content "$RepoPath/tsconfig.json" -Raw
        if ($content -match '"references"') {
            if (Test-Path "$RepoPath/tsconfig.src.json") {
                return "npx tsc --project tsconfig.src.json --noEmit"
            }
            return "npx tsc --build --noEmit"
        }
        return "npx tsc --noEmit"
    }
    return ""
}
