# Exit if there are any exceptions
$ErrorActionPreference = "Stop"

$NanoboxVersion    = "0.16.8"
$VagrantVersion    = "1.7.4"
$VirtualBoxVersion = "5.0.8"

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

# Download nanobox
$NanoboxSourceURL = "https://s3.amazonaws.com/tools.nanobox.io/installers/windows/nanobox.msi"
$NanoboxDest      = "$($NanoboxTmpDir)/nanobox.msi"

# Write-Host "Downloading nanobox: $($NanoboxVersion)"
# $client = New-Object System.Net.WebClient
# $client.DownloadFile($NanoboxSourceURL, $NanoboxDest)
# Write-Host "Downloaded nanobox: $($NanoboxVersion)"

# Write-Host "Copying nanobox: $($NanoboxVersion)"
Copy-Item nanobox.msi $NanoboxDest

# Download vagrant
$VagrantSourceURL = "https://dl.bintray.com/mitchellh/vagrant/vagrant_$($VagrantVersion).msi"
$VagrantDest      = "$($NanoboxTmpDir)/vagrant.msi"

Write-Host "Downloading vagrant: $($VagrantVersion)"
$client = New-Object System.Net.WebClient
$client.DownloadFile($VagrantSourceURL, $VagrantDest)
Write-Host "Downloaded vagrant: $($VagrantVersion)"

# Download virtualbox
$VirtualBoxSourceURL = "http://download.virtualbox.org/virtualbox/5.0.8/VirtualBox-5.0.8-103449-Win.exe"
$VirtualBoxDest      = "$($NanoboxTmpDir)/virtualbox.exe"

Write-Host "Downloading virtualbox: $($VirtualBoxVersion)"
$client = New-Object System.Net.WebClient
$client.DownloadFile($VirtualBoxSourceURL, $VirtualBoxDest)
Write-Host "Downloaded virtualbox: $($VirtualBoxVersion)"

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
        SourceFile="$($NanoboxTmpDir)/virtualbox.exe" />
      <MsiPackage SourceFile="$($NanoboxTmpDir)/vagrant.msi" />
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
