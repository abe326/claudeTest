# ==============================
# 空フォルダに .gitkeep を配置するスクリプト（古いPowerShell対応）
# ==============================

# ▼▼▼ 設定（書き換えてOK） ▼▼▼
$RootDir = "C:\Path\To\Your\Project"  # ← 対象のプロジェクトフォルダ（絶対パス）
$DryRun = $false                      # ← true にすると dry-run（書き込みなし）
# ▲▲▲ 設定ここまで ▲▲▲

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "gitkeep_log_$timestamp.txt"
$createdFolders = @()

# 除外するフォルダ
$excludeFolders = @(".git", "build", "out", "node_modules")

Write-Output "=== 空フォルダチェック開始 [$timestamp] ===" | Tee-Object -FilePath $logFile

# 空フォルダ判定
function Is-EmptyFolder($folder) {
    $items = Get-ChildItem -Path $folder -Force -Recurse -File -ErrorAction SilentlyContinue
    return ($items.Count -eq 0)
}

# フォルダを再帰的に走査
$folders = Get-ChildItem -Path $RootDir -Recurse -Directory -Force | Where-Object {
    $include = $true
    foreach ($ex in $excludeFolders) {
        if ($_.FullName -like "*\$ex*") {
            $include = $false
            break
        }
    }
    return $include
}

foreach ($folder in $folders) {
    if (Is-EmptyFolder $folder.FullName) {
        $gitkeepPath = Join-Path $folder.FullName ".gitkeep"
        if (-Not (Test-Path $gitkeepPath)) {
            if (-Not $DryRun) {
                New-Item -Path $gitkeepPath -ItemType File -Force | Out-Null
            }

            $createdFolders += $folder.FullName

            $logLine = if ($DryRun) { "[DRY-RUN] .gitkeep would be created in: $($folder.FullName)" }
                       else        { ".gitkeep created in: $($folder.FullName)" }

            $logLine | Tee-Object -FilePath $logFile -Append
        }
    }
}

if ($createdFolders.Count -eq 0) {
    "空フォルダは見つかりませんでした。" | Tee-Object -FilePath $logFile -Append
} else {
    "`n=== .gitkeep 作成完了 ===`n合計: $($createdFolders.Count) フォルダに作成" | Tee-Object -FilePath $logFile -Append
}

Write-Output "ログ出力完了: $logFile"
Pause
