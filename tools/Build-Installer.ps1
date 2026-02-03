# install prerequisites
if ((Get-Command iscc).Length -ne 1)
{
    Write-Host "Inno Setup (ISCC) not installed, installing now..." -ForegroundColor Yellow
    choco.exe install innosetup -y
}
else {
    Write-Host "Inno Setup (ISCC) installed, proceeding with build..."
}

# remove previous build
Remove-Item "build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "externalBins" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "installer/Output" -Recurse -Force -ErrorAction SilentlyContinue

# add external bins folder
New-Item "externalBins" -ItemType Directory -Force | Out-Null

# build application (.net 8.0)
dotnet publish src/app/PackersTools -c Release -o build/app -r win-x64 --self-contained true -p:Version="0.3.0" -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true

# fetch IntuneWinAppUtil.exe
$url = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe"
$out = "externalBins/intunewinapputil.exe"
Invoke-WebRequest -Uri $url -OutFile $out

# Create installer
iscc.exe installer\PackersTools.iss

# generate SHA256 hash for installer
$installer = Get-ChildItem "installer/Output" -Filter *.exe | Select-Object -First 1
if (-not $installer) {
    throw "Installer EXE not found"
}
$hash = Get-FileHash $installer.FullName -Algorithm SHA256
$output = "$($hash.Hash)  $($installer.Name)"
$output | Set-Content "$($installer.FullName).sha256" -Encoding ASCII
Write-Host "SHA256 generated:"
Write-Host $output