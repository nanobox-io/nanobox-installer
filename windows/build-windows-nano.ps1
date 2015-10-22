# Exit if there are any exceptions
$ErrorActionPreference = "Stop"

# Allows Windows to keep track of app for upgrades
$UpgradeCode = "f44a14ed-849a-4acd-a537-51395f7d5958"

# Needs to change with each release
$NanoboxVersion = "0.0.9"

# Final path to output
$OutputPath = "nanobox-micro.msi"

# Get the directory to this script
$Dir = Split-Path $script:MyInvocation.MyCommand.Path

# Lookup the WiX binaries, these will error if they're not on the Path
$WixHeat   = Get-Command heat | Select-Object -ExpandProperty Definition
$WixCandle = Get-Command candle | Select-Object -ExpandProperty Definition
$WixLight  = Get-Command light | Select-Object -ExpandProperty Definition

#--------------------------------------------------------------------
# Fetch nanobox binaries
#--------------------------------------------------------------------
# Create temp directory
$NanoboxTmpDir = [System.IO.Path]::GetTempPath()
$NanoboxTmpDir = [System.IO.Path]::Combine($NanoboxTmpDir, [System.IO.Path]::GetRandomFileName())
[System.IO.Directory]::CreateDirectory($NanoboxTmpDir) | Out-Null
Write-Host "nanobox temp dir: $($NanoboxTmpDir)"

# Download nanobox
$nanoboxSourceURL = "https://s3.amazonaws.com/tools.nanobox.io/cli/windows/amd64/nanobox.exe"
$nanoboxDest      = "$($NanoboxTmpDir)/nanobox.exe"

Write-Host "Downloading nanobox: $($NanoboxVersion)"
$client = New-Object System.Net.WebClient
$client.DownloadFile($nanoboxSourceURL, $nanoboxDest)
Write-Host "Downloaded nanobox: $($NanoboxVersion)"

#--------------------------------------------------------------------
# MSI preparation
#--------------------------------------------------------------------
$InstallerTmpDir = [System.IO.Path]::GetTempPath()
$InstallerTmpDir = [System.IO.Path]::Combine($InstallerTmpDir, [System.IO.Path]::GetRandomFileName())
[System.IO.Directory]::CreateDirectory($InstallerTmpDir) | Out-Null
[System.IO.Directory]::CreateDirectory("$($InstallerTmpDir)\resources") | Out-Null
Write-Host "Installer temp dir: $($InstallerTmpDir)"

Copy-Item "$($Dir)\resources\bg_banner.bmp" `
    -Destination "$($InstallerTmpDir)\resources\bg_banner.bmp"
Copy-Item "$($Dir)\resources\bg_dialog.bmp" `
    -Destination "$($InstallerTmpDir)\resources\bg_dialog.bmp"
Copy-Item "$($Dir)\resources\license.rtf" `
    -Destination "$($InstallerTmpDir)\resources\license.rtf"
Copy-Item "$($Dir)\resources\nanobox-en-us.wxl" `
    -Destination "$($InstallerTmpDir)\nanobox-en-us.wxl"
Copy-Item "$($Dir)\resources\nanodesk.ico" `
    -Destination "$($InstallerTmpDir)\resources\nanodesk.ico"

# nanobox-config.wxi
$contents = @"
<?xml version="1.0" encoding="utf-8"?>
<Include>
  <?define VersionNumber="$($NanoboxVersion)" ?>
  <?define DisplayVersionNumber="$($NanoboxVersion)" ?>

  <!--
    Upgrade code must be unique per version installer.
    This is used to determine uninstall/reinstall cases.
  -->
  <?define UpgradeCode="$($UpgradeCode)" ?>
</Include>
"@
$contents | Out-File `
    -Encoding ASCII `
    -FilePath "$($InstallerTmpDir)\nanobox-config.wxi"

# nanobox-main.wxi
$contents = @"
<?xml version="1.0"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi" xmlns:util="http://schemas.microsoft.com/wix/UtilExtension">
  <!-- Include our wxi -->
  <?include "$($InstallerTmpDir)\nanobox-config.wxi" ?>

  <!-- The main product (Product ID is generated on each build) -->
  <Product Id="*"
           Language="!(loc.LANG)"
           Name="!(loc.ProductName)"
           Version="`$(var.VersionNumber)"
           Manufacturer="!(loc.ManufacturerName)"
           UpgradeCode="`$(var.UpgradeCode)">

    <!-- Define the package information -->
    <Package Compressed="yes"
             InstallerVersion="200"
             InstallPrivileges="elevated"
             InstallScope="perMachine"
             Manufacturer="!(loc.ManufacturerName)" />

    <!-- Disallow installing older versions until the new version is removed -->
    <!-- Note that this creates the RemoveExistingProducts action -->
    <MajorUpgrade DowngradeErrorMessage="A later version of nanobox is installed. Please remove this version first. Setup will now exit."
                  Schedule="afterInstallInitialize" />

    <!-- The source media for the installer -->
    <Media Id="1"
           Cabinet="nanobox.cab"
           CompressionLevel="high"
           EmbedCab="yes" />

    <!-- Require Windows NT Kernel -->
    <Condition Message="This application is only supported on Windows 2000 or higher.">
      <![CDATA[Installed or (VersionNT >= 500)]]>
    </Condition>

    <!-- Get the proper system directory -->
    <SetDirectory Id="WINDOWSVOLUME" Value="[WindowsVolume]" />

    <!-- The directory where we'll install nanobox -->
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="WINDOWSVOLUME">
        <Directory Id="MANUFACTURERDIR" Name="Pagoda Box">
          <Directory Id="NANOBOXAPPDIR" Name="nanobox">
            <Component Id="nanoboxBin"
              Guid="{5db86fbc-00f3-4057-9799-0800253252ec}">
              <!--
                Add our bin dir to the PATH so people can use
                nanobox right away in the shell.
              -->
              <Environment Id="Environment"
                Name="PATH"
                Action="set"
                Part="last"
                System="yes"
                Value="[NANOBOXAPPDIR]" />

              <!-- We need this to avoid an ICE validation error -->
              <CreateFolder />

            </Component>
          </Directory>
        </Directory>
      </Directory>
    </Directory>

    <!-- Add nanobox icon -->
    <Icon Id="icon.ico" SourceFile="$($InstallerTmpDir)\resources\nanodesk.ico"/>
    <Property Id="ARPPRODUCTICON" Value="icon.ico" />

    <!-- Define the features of our install -->
    <Feature Id="nanoboxFeature"
             Title="!(loc.ProductName)"
             Level="1">
      <ComponentGroupRef Id="nanoboxDir" />
      <ComponentRef Id="nanoboxBin" />
    </Feature>

    <!-- WixUI configuration so we can have a UI -->
    <Property Id="WIXUI_INSTALLDIR" Value="NANOBOXAPPDIR" />

    <UIRef Id="nanoboxUI_InstallDir" />
    <UI Id="nanoboxUI_InstallDir">
      <UIRef Id="WixUI_InstallDir" />
    </UI>

    <WixVariable Id="WixUILicenseRtf" Value="$($InstallerTmpDir)\resources\license.rtf" />
    <WixVariable Id="WixUIDialogBmp" Value="$($InstallerTmpDir)\resources\bg_dialog.bmp" />
    <WixVariable Id="WixUIBannerBmp" Value="$($InstallerTmpDir)\resources\bg_banner.bmp" />
  </Product>
</Wix>
"@
$contents | Out-File `
    -Encoding ASCII `
    -FilePath "$($InstallerTmpDir)\nanobox-main.wxs"

#--------------------------------------------------------------------
# Create installer
#--------------------------------------------------------------------
# Run heat (harvest file tool)
Write-Host "Running heat.exe"
&$WixHeat dir $NanoboxTmpDir `
    -nologo `
    -srd `
    -gg `
    -cg nanoboxDir `
    -dr NANOBOXAPPDIR `
    -var 'var.nanoboxSourceDir' `
    -out "$($InstallerTmpDir)\nanobox-files.wxs"

# Run candle (compiler)
Write-Host "Running candle.exe"
$CandleArgs = @(
    "-nologo",
    "-I$($InstallerTmpDir)",
    "-dnanoboxSourceDir=$($NanoboxTmpDir)",
    "-out $InstallerTmpDir\ ",
    "$($InstallerTmpDir)\nanobox-files.wxs",
    "$($InstallerTmpDir)\nanobox-main.wxs"
)
Start-Process -NoNewWindow -Wait `
    -ArgumentList $CandleArgs -FilePath $WixCandle

# Run light (linker)
Write-Host "Running light.exe"
&$WixLight `
    -nologo `
    -ext WixUIExtension `
    -ext WixUtilExtension `
    -spdb `
    -cultures:en-us `
    -loc "$($InstallerTmpDir)\nanobox-en-us.wxl" `
    -out $OutputPath `
    "$($InstallerTmpDir)\nanobox-files.wixobj" `
    "$($InstallerTmpDir)\nanobox-main.wixobj"

Write-Host "Installer at: $($OutputPath)"

#--------------------------------------------------------------------
# Clean up
#--------------------------------------------------------------------
Remove-Item -Recurse -Force $InstallerTmpDir
Remove-Item -Recurse -Force $NanoboxTmpDir
