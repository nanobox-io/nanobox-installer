### Building
[wixtoolset](http://wixtoolset.org/) is required    
to build nanobox-cli and nanobox-boot2docker bundle, open powershell    
and change to windows directory and run `build-windows.bat`   

to build the full bundle, open powershell and change to windows    
directory and run `build-windows-all.bat`   

```
git clone git@github.com:nanobox-io/nanobox-installer.git C:\src\nanobox-installer
cd C:\src\nanobox-installer\windows

# Build nanobox-only installer (fetches nanobox cli from s3)
.\build-windows.bat

# Build nanobox-bundle installer (fetches vagrant and virtualbox)
.\build-windows-all.bat

# Upload to s3 (may require credentials)
.\upload.bat
```
