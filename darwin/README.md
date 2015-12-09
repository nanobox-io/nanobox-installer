### Building
```
git clone git@github.com:nanobox-io/nanobox-installer.git /opt/src/nanobox-installer
cd /opt/src/nanobox-installer/darwin

# Build nanobox-only installer (fetches nanobox cli from s3)
sudo ./build-darwin.sh

# Build nanobox-bundle installer (fetches vagrant and virtualbox)
sudo ./build-darwin-all.sh

# Upload to s3 (may require credentials)
./upload
```
