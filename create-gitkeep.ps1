# =====================================
# 最も深い空ディレクトリにのみ .gitkeep を配置するスクリプト
# =====================================

# ▼ 設定：プロジェクトルートとDryRun
$RootDir = "C:\Path\To\Your\Project"
$DryRun = $false

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "gitkeep_log_$timestamp.txt"
$createdFolders = @()

# 除外対象
$excludeFolders = @(".git", "build", "out", "node_modules")

Write-Output "=== 空フォルダチェック開始 [$timestamp] ===" | Tee-Object -FilePath $logFile

# 空フォルダ判定：中にファイルがなければ空とする（隠し含む）
function Is-EmptyFolder($folderPath) {
    $items = Get-ChildItem -Path $folderPath -Force -File -Recurse -ErrorAction SilentlyContinue
    return ($items.Count -eq 0)
}

# フォルダ取得（深い順にソート）
$folders = Get-ChildItem -Path $RootDir -Recurse -Directory -Force |
    Where-Object {
        foreach ($ex in $excludeFolders) {
            if ($_.FullName -like "*\$ex*") { return $false }
        }
        return $true
    } |
    Sort-Object { $_.FullName.Split('\').Count } -Descending  # 深い順に処理！

# 既に下位フォルダで処理済かを判定用
$alreadyProcessed = @{}

foreach ($folder in $folders) {
    if ($alreadyProcessed.ContainsKey($folder.FullName)) {
        continue  # すでに子のどこかで処理済
    }

    if (Is-EmptyFolder $folder.FullName) {
        $gitkeepPath = Join-Path $folder.FullName ".gitkeep"
        if (-Not (Test-Path $gitkeepPath)) {
            if (-Not $DryRun) {
                New-Item -Path $gitkeepPath -ItemType File -Force | Out-Null
            }

            $createdFolders += $folder.FullName

            $logLine = if ($DryRun) {
                "[DRY-RUN] .gitkeep would be created in: $($folder.FullName)"
            } else {
                ".gitkeep created in: $($folder.FullName)"
            }

            $logLine | Tee-Object -FilePath $logFile -Append

            # 親ディレクトリは空とみなさないよう記録
            $parent = (Get-Item $folder.FullName).Parent.FullName
            while ($parent -and -not $alreadyProcessed.ContainsKey($parent)) {
                $alreadyProcessed[$parent] = $true
                $parent = (Get-Item $parent).Parent.FullName
            }
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
