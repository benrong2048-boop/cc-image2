param(
    [string]$Prompt,

    [string]$PromptFile,

    [string[]]$ReferenceImage,

    [string]$Mask,

    [ValidateSet('auto', 'generate', 'edit')]
    [string]$Mode = 'auto',

    [switch]$DryRun,

    [Parameter(Mandatory)]
    [string]$Out,

    [ValidateSet('1024x1024', '1536x1024', '1024x1536', '1536x1536', '1536x2048', '2048x1536', '2048x2048', '2160x3840', '3840x2160')]
    [string]$Size = '1536x2048',

    [ValidateSet('low', 'medium', 'high', 'auto')]
    [string]$Quality = 'high'
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Prompt) -and [string]::IsNullOrWhiteSpace($PromptFile)) {
    throw '请传入 -Prompt 或 -PromptFile。'
}
if (-not [string]::IsNullOrWhiteSpace($Prompt) -and -not [string]::IsNullOrWhiteSpace($PromptFile)) {
    throw '只能使用 -Prompt 或 -PromptFile 其中之一。'
}
if (-not [string]::IsNullOrWhiteSpace($PromptFile)) {
    if (-not (Test-Path -LiteralPath $PromptFile)) {
        throw "未找到提示词文件：$PromptFile"
    }
    $Prompt = Get-Content -LiteralPath $PromptFile -Raw -Encoding utf8
}

$hasReference = $null -ne $ReferenceImage -and $ReferenceImage.Count -gt 0
if ($Mode -eq 'generate' -and $hasReference) {
    throw '生成模式不能传入参考图。请使用 -Mode edit，或保留默认 auto。'
}
if ($Mode -eq 'edit' -and -not $hasReference) {
    throw '编辑模式必须至少传入一张 -ReferenceImage。'
}
$operation = if ($Mode -eq 'edit' -or $hasReference) { 'edit' } else { 'generate' }

$resolvedReferences = @()
if ($hasReference) {
    foreach ($reference in $ReferenceImage) {
        if ([string]::IsNullOrWhiteSpace($reference)) {
            throw '参考图路径不能为空。'
        }
        $resolvedReference = [System.IO.Path]::GetFullPath($reference)
        if (-not (Test-Path -LiteralPath $resolvedReference)) {
            throw "未找到参考图：$reference"
        }
        $resolvedReferences += $resolvedReference
    }
}

$resolvedMask = $null
if (-not [string]::IsNullOrWhiteSpace($Mask)) {
    if ($operation -ne 'edit') {
        throw 'Mask 只能与参考图编辑模式一起使用。'
    }
    $resolvedMask = [System.IO.Path]::GetFullPath($Mask)
    if (-not (Test-Path -LiteralPath $resolvedMask)) {
        throw "未找到蒙版：$Mask"
    }
}

if (-not $DryRun -and (-not $env:OPENAI_API_KEY -or -not $env:OPENAI_BASE_URL)) {
    throw '未检测到 CC Switch 的 OPENAI_API_KEY 或 OPENAI_BASE_URL。请确认 CC Switch 已配置后重启 Codex。'
}

$runner = Join-Path $env:USERPROFILE '.codex/skills/.system/imagegen/scripts/image_gen.py'
if (-not (Test-Path $runner)) {
    throw "未找到图片生成脚本：$runner"
}

$resolvedOut = [System.IO.Path]::GetFullPath($Out)
$outDirectory = Split-Path -Parent $resolvedOut
if (-not (Test-Path $outDirectory)) {
    New-Item -ItemType Directory -Force -Path $outDirectory | Out-Null
}
if (Test-Path $resolvedOut) {
    throw "输出文件已存在：$resolvedOut。请使用新的文件名，避免覆盖已有图片。"
}

$runnerArgs = @(
    $runner,
    $operation,
    '--model', 'gpt-image-2',
    '--prompt', $Prompt,
    '--size', $Size,
    '--quality', $Quality,
    '--output-format', 'png',
    '--out', $resolvedOut,
    '--no-augment'
)
if ($operation -eq 'edit') {
    foreach ($reference in $resolvedReferences) {
        $runnerArgs += @('--image', $reference)
    }
    if ($resolvedMask) {
        $runnerArgs += @('--mask', $resolvedMask)
    }
}
if ($DryRun) {
    $runnerArgs += '--dry-run'
}

Write-Host "CC Image 2 模式：$operation"
if ($operation -eq 'edit') {
    Write-Host "参考图数量：$($resolvedReferences.Count)"
}
& python @runnerArgs
if ($LASTEXITCODE -ne 0) {
    throw "gpt-image-2 调用失败，退出码：$LASTEXITCODE"
}
if (-not $DryRun -and -not (Test-Path $resolvedOut)) {
    throw '接口返回成功，但没有找到输出图片。'
}
if (-not $DryRun) {
    Get-Item $resolvedOut | Select-Object FullName, Length, LastWriteTime
}