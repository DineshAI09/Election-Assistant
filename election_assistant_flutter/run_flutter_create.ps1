# Run this in a NEW terminal (after installing Flutter and adding it to PATH).
# Or run: powershell -ExecutionPolicy Bypass -File run_flutter_create.ps1

Set-Location $PSScriptRoot

# If flutter is not in PATH, try common locations
$flutterCmd = $null
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutterCmd = "flutter"
} else {
    $tryPaths = @(
        "C:\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat"
    )
    foreach ($p in $tryPaths) {
        if (Test-Path $p) {
            $flutterCmd = $p
            Write-Host "Using: $p"
            break
        }
    }
}

if (-not $flutterCmd) {
    Write-Host "Flutter not found. Add Flutter to PATH or set it in this script." -ForegroundColor Red
    exit 1
}

& $flutterCmd create . --project-name election_assistant
if ($LASTEXITCODE -eq 0) {
    Write-Host "Done. You can now run: flutter pub get && flutter run" -ForegroundColor Green
}
