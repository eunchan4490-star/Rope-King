param(
    [Parameter(Mandatory = $true)]
    [string]$Message,

    [Parameter(Mandatory = $true)]
    [string[]]$Files
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

if ((git branch --show-current) -ne "main") {
    throw "Android 배포는 main 브랜치에서만 실행할 수 있습니다."
}

foreach ($file in $Files) {
    if ([string]::IsNullOrWhiteSpace($file) -or $file -match '(^|[\\/])\.\.?([\\/]|$)') {
        throw "안전하지 않은 파일 경로입니다: $file"
    }
    if (-not (Test-Path -LiteralPath $file)) {
        throw "커밋할 파일을 찾을 수 없습니다: $file"
    }
}

& godot_console.exe --headless --path . --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Godot 프로젝트 검증에 실패했습니다." }

& godot_console.exe --headless --path . --quit-after 5
if ($LASTEXITCODE -ne 0) { throw "Godot 실행 검증에 실패했습니다." }

& git diff --check
if ($LASTEXITCODE -ne 0) { throw "Git diff 검사에 실패했습니다." }

& git add -- $Files
$stagedFiles = @(git diff --cached --name-only)
if ($stagedFiles.Count -eq 0) {
    throw "커밋할 변경사항이 없습니다."
}

& git commit -m $Message
if ($LASTEXITCODE -ne 0) { throw "Git 커밋에 실패했습니다." }

& git push origin main
if ($LASTEXITCODE -ne 0) { throw "GitHub push에 실패했습니다." }

$commitSha = (git rev-parse HEAD).Trim()
$run = $null
for ($attempt = 0; $attempt -lt 30 -and $null -eq $run; $attempt++) {
    $runs = gh run list --workflow "Android APK" --branch main --commit $commitSha --limit 1 --json databaseId,url,status,conclusion | ConvertFrom-Json
    if ($runs.Count -gt 0) {
        $run = $runs[0]
        break
    }
    Start-Sleep -Seconds 2
}

if ($null -eq $run) {
    throw "이 커밋의 Android APK 빌드를 찾지 못했습니다."
}

& gh run watch $run.databaseId --exit-status
if ($LASTEXITCODE -ne 0) { throw "Android APK 빌드가 실패했습니다: $($run.url)" }

$downloadDirectory = Join-Path $projectRoot ("builds\\run-" + $run.databaseId)
New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null
& gh run download $run.databaseId --name "Rope-King-Android" --dir $downloadDirectory
if ($LASTEXITCODE -ne 0) { throw "APK 다운로드에 실패했습니다." }

$apk = Get-ChildItem -LiteralPath $downloadDirectory -Filter "*.apk" -Recurse | Select-Object -First 1
if ($null -eq $apk) { throw "다운로드 결과에서 APK를 찾지 못했습니다." }

Write-Host "빌드 성공: $($run.url)"
Write-Host "설치 APK: $($apk.FullName)"
