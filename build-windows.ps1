# Build Windows EXE
Write-Host "Building Secondary Screen Host..." -ForegroundColor Green

$projectPath = Join-Path $PSScriptRoot "WindowsApp\SecondaryScreenHost.csproj"
$outputPath = Join-Path $PSScriptRoot "Build\Windows"

# Clean previous build
if (Test-Path $outputPath) {
    Remove-Item -Path $outputPath -Recurse -Force
}

# Build single-file executable
Write-Host "Building self-contained executable..." -ForegroundColor Yellow

dotnet publish $projectPath `
    -c Release `
    -r win-x64 `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:PublishTrimmed=false `
    -o $outputPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild successful!" -ForegroundColor Green
    Write-Host "Executable location: $outputPath\SecondaryScreenHost.exe" -ForegroundColor Cyan
    
    # Create installer directory
    $installerPath = Join-Path $PSScriptRoot "Build\Installer"
    if (-not (Test-Path $installerPath)) {
        New-Item -ItemType Directory -Path $installerPath | Out-Null
    }
    
    # Copy to installer directory
    Copy-Item -Path "$outputPath\SecondaryScreenHost.exe" -Destination $installerPath -Force
    
    Write-Host "`nInstaller ready at: $installerPath" -ForegroundColor Green
    
    # Get file size
    $fileSize = (Get-Item "$outputPath\SecondaryScreenHost.exe").Length / 1MB
    Write-Host "File size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan
} else {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    exit 1
}

# Create README for distribution
$readmePath = Join-Path $installerPath "README.txt"
@"
Secondary Screen Host - Windows Application
Version 1.0.0

INSTALLATION:
1. Run SecondaryScreenHost.exe
2. Click 'Start Server' to begin
3. Note the IP address displayed
4. Connect from your iPad app using this IP address

SYSTEM REQUIREMENTS:
- Windows 10 or later (64-bit)
- .NET Runtime (included in this build)
- Network connection (WiFi or Ethernet)

FIREWALL:
If the iPad cannot connect, you may need to allow the app through Windows Firewall.
Run this command in PowerShell (as Administrator):

netsh advfirewall firewall add rule name="Secondary Screen" dir=in action=allow protocol=TCP localport=8888

USAGE:
1. Start the server on Windows
2. Open the iPad app
3. Connect using auto-discovery or manual IP
4. Your iPad is now a secondary display!

For more information, visit the documentation.
"@ | Out-File -FilePath $readmePath -Encoding UTF8

Write-Host "`nREADME.txt created for distribution" -ForegroundColor Cyan
