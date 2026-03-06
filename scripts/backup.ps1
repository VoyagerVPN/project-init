#Requires -Version 5.1
<#
.SYNOPSIS
    Универсальный скрипт архивации проекта.
.DESCRIPTION
    Создаёт архив в формате [project]-yyyy-MM-dd-HH-mm (сортировка по возрастанию).
    Исключения: захардкоженные + backup.config.json (поле exclude).
    Каждый том архива < 1 ГБ. Поддерживает WinRAR, 7-Zip, Compress-Archive.
.PARAMETER ProjectRoot
    Корень проекта. По умолчанию — родитель папки scripts или текущая директория.
.PARAMETER OutputDir
    Папка для архива. По умолчанию — .temp/backup внутри проекта.
.PARAMETER SkipRun
    Только вывод отчёта без создания архива (для QA).
#>

param(
    [string]$ProjectRoot = "",
    [string]$OutputDir = "",
    [switch]$SkipRun
)

$ErrorActionPreference = "Stop"

# Определение корня проекта
if (-not $ProjectRoot) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $parentDir = Split-Path -Parent $scriptDir
    # Скрипт в <root>/scripts/ → корень = parent
    if ((Split-Path -Leaf $scriptDir) -eq "scripts") {
        $ProjectRoot = $parentDir
    } else {
        # Скрипт в корне или в другом месте — корень = папка скрипта
        $ProjectRoot = $scriptDir
    }
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

# Имя проекта: из названия папки (без спецсимволов)
# Имя архива: project-yyyy-MM-dd-HH-mm — сортировка по возрастанию, читаемый формат
$ProjectName = (Get-Item $ProjectRoot).Name -replace '[^\w\-]', '-'
$DateTimeStr = Get-Date -Format "yyyy-MM-dd-HH-mm"
$ArchiveBaseName = "${ProjectName}-${DateTimeStr}"

# Выходная папка: .temp/backup внутри проекта
if (-not $OutputDir) {
    $OutputDir = Join-Path $ProjectRoot ".temp\backup"
}
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
$OutputDir = (Resolve-Path $OutputDir).Path

# Захардкоженные исключения: node_modules, легко восстанавливаемые результаты сборки
$HardcodedExclude = @(
    "node_modules",
    "out",
    "dist",
    ".git",
    "coverage",
    "release",
    "*.blockmap",
    "*.log",
    ".DS_Store",
    "Thumbs.db",
    ".env",
    ".env.*",
    "*.exe",
    "*.deb",
    "*.rpm",
    "*.AppImage",
    "*.dmg",
    "*.snap"
)

# Дополнительные исключения из backup.config.json (если есть)
$ConfigPath = Join-Path $ProjectRoot "backup.config.json"
$ExcludePatterns = $HardcodedExclude.Clone()
if (Test-Path $ConfigPath) {
    try {
        $config = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($config.exclude -and $config.exclude.Count -gt 0) {
            $ExcludePatterns = @($HardcodedExclude + $config.exclude) | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique
        }
    } catch {
        Write-Warning "Ошибка чтения backup.config.json: $_"
    }
}

# Поиск архиватора
function Find-WinRar {
    $paths = @(
        "C:\Program Files\WinRAR\Rar.exe",
        "C:\Program Files (x86)\WinRAR\Rar.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Find-7Zip {
    $paths = @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

# WinRAR: максимальное сжатие (-m5), тома по 998 МБ
# Документация: маски ПАПОК с wildcards обязаны заканчиваться на \ (trailing backslash).
# Пример: *\node_modules\ — исключает node_modules в любой вложенности.
# Файлы: *.log, *.exe — без слеша.
function New-ArchiveWithWinRar {
    param([string]$RarExe, [string]$BaseName)
    $archivePath = Join-Path $OutputDir $BaseName
    $prevDir = Get-Location
    Set-Location $ProjectRoot

    $excludeFile = Join-Path $env:TEMP "backup-exclude-$(Get-Random).txt"
    $excludeLines = @()
    foreach ($p in $ExcludePatterns) {
        $p = $p.Trim()
        if ($p -match '^\*\.') {
            # *.log, *.exe — маска файлов (без trailing \)
            $excludeLines += $p
        } elseif ($p -eq ".env" -or $p -eq ".env.*") {
            # .env (файл/папка) и .env.* (файлы) — явные маски
            $excludeLines += "*\.env"
            $excludeLines += "*\.env\"
            if ($p -eq ".env.*") { $excludeLines += "*.env.*" }
        } else {
            # Папка: *\name\ — trailing \ обязателен для маски папки (WinRAR docs)
            $excludeLines += "*\$p\"
        }
    }
    $excludeLines | Sort-Object -Unique | Set-Content $excludeFile -Encoding ASCII

    try {
        $argList = @("a", "-m5", "-r", "-v998m", "-ep1", "-x@`"$excludeFile`"", "`"$archivePath.rar`"", ".")
        $proc = Start-Process -FilePath $RarExe -ArgumentList $argList -PassThru -Wait -NoNewWindow
        return $proc.ExitCode
    } finally {
        Remove-Item $excludeFile -Force -ErrorAction SilentlyContinue
        Set-Location $prevDir
    }
}

# 7-Zip: максимальное сжатие (-mx=9)
function New-ArchiveWith7Zip {
    param([string]$7zExe, [string]$BaseName)
    $archivePath = Join-Path $OutputDir $BaseName
    $prevDir = Get-Location
    Set-Location $ProjectRoot

    $excludeArgs = $ExcludePatterns | ForEach-Object {
        $p = $_.Trim().TrimStart('*')
        if ($p) { "-xr!$p" }
    } | Where-Object { $_ }
    $argList = @("a", "-t7z", "-mx=9", "-r") + $excludeArgs + @("`"$archivePath.7z`"", "*")

    $proc = Start-Process -FilePath $7zExe -ArgumentList $argList -PassThru -Wait -NoNewWindow
    Set-Location $prevDir
    return $proc.ExitCode
}

# Compress-Archive (fallback): ZIP без тома, рекурсивное исключение
function New-ArchiveWithPowerShell {
    param([string]$BaseName)
    $archivePath = Join-Path $OutputDir "$BaseName.zip"
    $prevDir = Get-Location
    Set-Location $ProjectRoot

    function ShouldExclude {
        param([string]$RelativePath)
        $parts = $RelativePath -split [IO.Path]::DirectorySeparatorChar
        foreach ($pat in $script:ExcludePatterns) {
            $clean = $pat -replace '\*', ''
            foreach ($part in $parts) {
                if ($part -eq $clean -or ($pat.StartsWith("*") -and $part -like $pat) -or $part -like $pat) {
                    return $true
                }
            }
        }
        return $false
    }

    $files = @(Get-ChildItem -Path . -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object {
        $rel = $_.FullName.Substring($ProjectRoot.Length + 1).Replace("\", "/")
        -not (ShouldExclude -RelativePath $rel)
    })
    if ($files.Count -eq 0) {
        throw "Нет файлов для архивации после исключений"
    }
    Compress-Archive -Path $files.FullName -DestinationPath $archivePath -CompressionLevel Optimal -Force
    Set-Location $prevDir
    return 0
}

# --- Основной поток ---
$Report = @()
$Report += "=== Отчёт архивации ==="
$Report += "Дата: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$Report += "Проект: $ProjectRoot"
$Report += "Имя архива: $ArchiveBaseName"
$Report += "Выход: $OutputDir"
$Report += ""

if (-not (Test-Path $ProjectRoot)) {
    $Report += "ОШИБКА: Папка проекта не найдена: $ProjectRoot"
    $Report | Write-Host
    exit 1
}

$RarExe = Find-WinRar
$7zExe = Find-7Zip

if ($RarExe) {
    $Report += "Архиватор: WinRAR (макс. сжатие, тома 998 МБ)"
} elseif ($7zExe) {
    $Report += "Архиватор: 7-Zip (макс. сжатие)"
} else {
    $Report += "Архиватор: PowerShell Compress-Archive (ZIP)"
    $Report += "Подсказка: установи WinRAR или 7-Zip для лучшего сжатия"
}
$Report += ""

if ($SkipRun) {
    $Report += "[SkipRun] Архив не создаётся."
    $Report | ForEach-Object { Write-Host $_ }
    exit 0
}

$exitCode = 1
try {
    if ($RarExe) {
        $exitCode = New-ArchiveWithWinRar -RarExe $RarExe -BaseName $ArchiveBaseName
    } elseif ($7zExe) {
        $exitCode = New-ArchiveWith7Zip -7zExe $7zExe -BaseName $ArchiveBaseName
    } else {
        $exitCode = New-ArchiveWithPowerShell -BaseName $ArchiveBaseName
    }
} catch {
    $Report += "ОШИБКА: $_"
    $Report | ForEach-Object { Write-Host $_ }
    exit 1
}

# Размер результата
$archives = Get-ChildItem -Path $OutputDir -Filter "$ArchiveBaseName*" -ErrorAction SilentlyContinue
if ($archives) {
    $totalSize = ($archives | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($totalSize / 1MB, 2)
    $Report += "Создано файлов: $($archives.Count)"
    $Report += "Общий размер: $sizeMB МБ"
    foreach ($a in $archives) {
        $Report += "  - $($a.Name) ($([math]::Round($a.Length / 1MB, 2)) МБ)"
    }
} else {
    $Report += "ПРЕДУПРЕЖДЕНИЕ: Файлы архива не найдены в $OutputDir"
}

$Report += ""
if ($exitCode -eq 0) {
    $Report += "Статус: УСПЕХ"
} else {
    $Report += "Статус: ОШИБКА (exit code: $exitCode)"
}

$Report | ForEach-Object { Write-Host $_ }
exit $exitCode
