# Exit if there are any exceptions
$ErrorActionPreference = "Stop"

$NanoboxVersion    = "0.18.2"
$DockerToolboxVersion = "1.11.1b"

$OutputPath = "nanobox-bundle.exe"

# Needs to stay the same every release
$UpgradeCode = "aebc37e1-83e6-4833-8e95-83c42a2fa1a9"

# Lookup the WiX binaries, these will error if they're not on the Path
$WixCandle = Get-Command candle | Select-Object -ExpandProperty Definition
$WixLight  = Get-Command light | Select-Object -ExpandProperty Definition

#--------------------------------------------------------------------
# Fetch installers
#--------------------------------------------------------------------
# Create temp directory
$NanoboxTmpDir = [System.IO.Path]::GetTempPath()
$NanoboxTmpDir = [System.IO.Path]::Combine($NanoboxTmpDir, [System.IO.Path]::GetRandomFileName())
[System.IO.Directory]::CreateDirectory($NanoboxTmpDir) | Out-Null
Write-Host "nanobox temp dir: $($NanoboxTmpDir)"

# Move nanobox
$NanoboxDest      = "$($NanoboxTmpDir)/nanobox.msi"
Write-Host "Copying nanobox: $($NanoboxVersion)"
Copy-Item nanobox.msi $NanoboxDest

# Download Docker Toolbox
$DockerToolboxSourceURL = "https://github.com/docker/toolbox/releases/download/v$($DockerToolboxVersion)/DockerToolbox-$($DockerToolboxVersion).exe"
$DockerToolboxDest      = "$($NanoboxTmpDir)/DockerToolbox.exe"

Write-Host "Downloading Docker Toolbox: $($DockerToolboxVersion)"
$client = New-Object System.Net.WebClient
$client.DownloadFile($DockerToolboxSourceURL, $DockerToolboxDest)
Write-Host "Downloaded Docker Toolbox: $($DockerToolboxVersion)"

#--------------------------------------------------------------------
# Write simple WIX source file
#--------------------------------------------------------------------
$contents = @"
<?xml version="1.0"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi" 
    xmlns:bal="http://schemas.microsoft.com/wix/BalExtension">
  <Bundle 
    Version="$($NanoboxVersion)"
    Manufacturer="Pagoda Box"
    Name="nanobox"
    IconSourceFile="resources\nanodesk.ico"
    UpgradeCode="$($UpgradeCode)">

    <BootstrapperApplicationRef Id="WixStandardBootstrapperApplication.RtfLicense">
      <bal:WixStandardBootstrapperApplication
        LicenseFile="resources\license.rtf"
        LogoFile="resources\nanobox.png"
        ShowVersion="no" />
    </BootstrapperApplicationRef>

    <Chain>
      <ExePackage
        InstallCommand="--silent"
        SourceFile="$($NanoboxTmpDir)/DockerToolbox.exe" />
      <MsiPackage SourceFile="$($NanoboxTmpDir)/nanobox.msi" />
    </Chain>
  </Bundle>
</Wix>
"@
$contents | Out-File `
  -Encoding ASCII `
  -FilePath "$($NanoboxTmpDir)\nanobox-bundle.wxs"

#--------------------------------------------------------------------
# Create installer
#--------------------------------------------------------------------
# Run candle (compiler)
Write-Host "Running candle.exe"
$CandleArgs = @(
  "-nologo",
  "-ext WixBalExtension",
  "-out $NanoboxTmpDir\ ",
  "$($NanoboxTmpDir)\nanobox-bundle.wxs"
)
Start-Process -NoNewWindow -Wait `
  -ArgumentList $CandleArgs -FilePath $WixCandle

# Run light (linker)
Write-Host "Running light.exe"
&$WixLight `
  -nologo `
  -ext WixBalExtension `
  "$($NanoboxTmpDir)\nanobox-bundle.wixobj"

Write-Host "Installer at: $($OutputPath)"

#--------------------------------------------------------------------
# Clean up
#--------------------------------------------------------------------
Remove-Item -Recurse -Force $NanoboxTmpDir
