#!/bin/bash -x

# cleanup from a previous build
[ -f nanobox-bundle.dmg ] && rm -f nanobox-bundle.dmg
[ -f dmg/nanobox.pkg ] && rm -f dmg/nanobox.pkg
[ -f nanobox/bin/nanobox ] && rm -f nanobox/bin/nanobox

# prep dirs
mkdir -p \
  dmg/.support \
  nanobox/bin

# get mac bins
# nanobox
curl -fLkso nanobox/bin/nanobox 'https://s3.amazonaws.com/tools.nanobox.io/cli/darwin/amd64/nanobox'
chmod 755 nanobox/bin/nanobox
# virtualbox
[ -f dmg/.virtualbox.dmg ] || curl -fLkso dmg/.virtualbox.dmg 'http://download.virtualbox.org/virtualbox/5.0.0/VirtualBox-5.0.0-101573-OSX.dmg'
# vagrant
[ -f dmg/.vagrant.dmg ] || curl -fLkso dmg/.vagrant.dmg 'https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.3.dmg'
# boot2docker box
[ -f dmg/.nanobox-boot2docker.box ] || curl -fLkso dmg/.nanobox-boot2docker.box https://s3.amazonaws.com/tools.nanobox.io/boxes/vagrant/nanobox-boot2docker.box

#########################################################
#   PKG
#########################################################
# build core.pkg
echo "Building core.pkg"
pkgbuild \
  --root nanobox \
  --identifier com.nanobox.nanobox \
  --version "0.0.7" \
  --install-location "/opt/nanobox" \
  --scripts "scripts-all" \
  --timestamp=none \
  core.pkg


echo "Building nanobox.pkg"
# build nanobox.pkg
productbuild \
  --distribution nanobox.dist \
  --resources resources \
  --timestamp=none \
  dmg/nanobox.pkg

# cleanup cor build
rm -f core.pkg

#########################################################
#   DMG
#########################################################
# create temporary DMG
TMP_SIZE='1024m'
hdiutil create \
  -srcfolder "dmg" \
  -volname "nanobox" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" \
  -format UDRW \
  -size ${TMP_SIZE} \
  temp.dmg

# attach and read the temporary DMG device
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "./temp.dmg" | egrep '^/dev/' | sed 1q | awk '{print $1}')

sleep 2

# make finder deal look nice
echo '
  tell application "Finder"
    tell disk "'nanobox'"
      open
      set current view of container window to icon view
      set toolbar visible of container window to false
      set statusbar visible of container window to false
      set the bounds of container window to {100, 100, 710, 530}
      set theViewOptions to the icon view options of container window
      set arrangement of theViewOptions to not arranged
      set icon size of theViewOptions to 72
      delay 2
      set background picture of theViewOptions to file ".support:'background.png'"
      delay 5
      set position of item "'nanobox.pkg'" of container window to {465, 145}
      set position of item "'.uninstall.tool'" of container window to {465, 345}
      update without registering applications
      delay 5
    end tell
  end tell
' | osascript

# set the permissions and generate the final DMG
sudo chmod -Rf go-w /Volumes/nanobox
sync
hdiutil detach ${DEVICE}

hdiutil convert \
  "temp.dmg" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "nanobox-bundle.dmg"

# Set icon on .dmg
sips -i resources/nanodesk.icns
derez -only icns resources/nanodesk.icns > nanodesk.rsrc
rez -append nanodesk.rsrc -o nanobox-bundle.dmg
setfile -a C nanobox-bundle.dmg

# cleanup temp things
rm -f temp.dmg
rm -f nanodesk.rsrc
