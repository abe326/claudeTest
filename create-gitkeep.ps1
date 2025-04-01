通常実行（.gitkeep を作成）
.\create-gitkeep.ps1 -RootDir "C:\MyProject"
dry-run モード（作成せず確認）
.\create-gitkeep.ps1 -RootDir "C:\MyProject" -DryRun


param(
    [string]$RootDir = ".",
    [switch]$DryRun
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "gitkeep_log_$timestamp.txt"
$createdFolders = @()

# 除外するフォルダ名（カスタマイズ可）
$excludeFolders = @(".git", "build", "out", "node_modules")

Write-Output "=== 空フォルダチェック開始 [$timestamp] ===" | Tee-Object -FilePath $logFile

# 空ディレクトリか判定する関数
function Is-EmptyFolder($folder) {
    $items = Get-ChildItem -Path $folder -Force -Recurse -File -ErrorAction SilentlyContinue
    return ($items.Count -eq 0)
}

# 対象フォルダを再帰的に検索
$folders = Get-ChildItem -Path $RootDir -Recurse -Directory -Force | Where-Object {
    foreach ($ex in $excludeFolders) {
        if ($_.FullName -like "*\$ex*") { return $false }
    }
    return $true
}

foreach ($folder in $folders) {
    if (Is-EmptyFolder $folder.FullName) {
        $gitkeepPath = Join-Path $folder.FullName ".gitkeep"
        if (-Not (Test-Path $gitkeepPath)) {
            if (-Not $DryRun) {
                New-Item -Path $gitkeepPath -ItemType File -Force | Out-Null
            }
            $createdFolders += $folder.FullName
            "$($DryRun ? '[DRY-RUN] ' : '').gitkeep created in: $($folder.FullName)" | Tee-Object -FilePath $logFile -Append
        }
    }
}

if ($createdFolders.Count -eq 0) {
    "空フォルダは見つかりませんでした。" | Tee-Object -FilePath $logFile -Append
} else {
    "`n=== .gitkeep 作成完了 ===`n合計: $($createdFolders.Count) フォルダに作成" | Tee-Object -FilePath $logFile -Append
}

Write-Output "ログ出力完了: $logFile"
