$start = Get-Date

$scriptPath = $MyInvocation.MyCommand.Path
$grandParentDir = (Get-Item $scriptPath).Directory.Parent.FullName
$folderName = (Get-Item $grandParentDir).Name
$dst = Join-Path ([Environment]::GetFolderPath("Desktop")) $folderName

$excludeDirs = @(
    "main-applic\node_modules",
    ".git",
    ".vscode",
    "main-applic\.next",
    "main-applic\build",
    "main-applic\public\temporary",
    "main-applic\test-results",
    "main-applic\.swc"
) | ForEach-Object { Join-Path $grandParentDir $_ }

$robocopyArgs = @(
    $grandParentDir,
    $dst,
    "/MT:12",
    "/MIR",
    "/XA:SH",
    "/XJD",
    "/NFL",
    "/NDL",
    ($excludeDirs | ForEach-Object { "/XD"; $_ })
)

robocopy @robocopyArgs

$elapsed = (Get-Date) - $start
Write-Output "Copy completed at: $dst"
Write-Output ("Elapsed time: {0} seconds" -f $elapsed.TotalSeconds.ToString('N2'))
