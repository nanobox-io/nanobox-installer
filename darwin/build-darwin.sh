#!/bin/bash -x

# cleanup from a previous build
[ -f nanobox.dmg ] && rm -f nanobox.dmg
[ -f dmg/nanobox.pkg ] && rm -f dmg/nanobox.pkg
[ -f nanobox/bin/nanobox ] && rm -f nanobox/bin/nanobox
[ -f dmg/.dockertoolbox.uninstall.tool ] && rm -f dmg/.dockertoolbox.uninstall.tool
[ -f dmg/.DockerToolbox.pkg ] && rm -f dmg/.DockerToolbox.pkg
[ -d /Volumes/nanobox ] && hdiutil detach -force /Volumes/nanobox

# prep dirs
mkdir -p \
  dmg/.support \
  nanobox/bin

# get nanobox mac bins
if [ -f beta/nanobox-darwin ]; then
  cp beta/nanobox-darwin
else
  curl -fLkso nanobox/bin/nanobox 'https://s3.amazonaws.com/tools.nanobox.io/cli/darwin/amd64/nanobox'
fi
chmod 755 nanobox/bin/nanobox

# set icon for nanobox bin
sips -i resources/nanodesk.icns
derez -only icns resources/nanodesk.icns > nanodesk.rsrc
rez -append nanodesk.rsrc -o nanobox/bin/nanobox
setfile -a C nanobox/bin/nanobox

#########################################################
#   PKG
#########################################################
# build core.pkg
echo "Building core.pkg"
pkgbuild \
  --root nanobox \
  --identifier com.nanobox.nanobox \
  --version "0.16.15" \
  --install-location "/opt/nanobox" \
  --scripts "scripts" \
  --timestamp=none \
  core.pkg


echo "Building nanobox.pkg"
# build nanobox.pkg
productbuild \
  --distribution nanobox.dist \
  --resources resources \
  --timestamp=none \
  --sign "Developer ID Installer: Eric Graybill" \
  dmg/nanobox.pkg

# cleanup cor build
rm -f core.pkg

# set icon for pkg file
rez -append nanodesk.rsrc -o dmg/nanobox.pkg
setfile -a C dmg/nanobox.pkg

#########################################################
#   DMG
#########################################################
# create temporary DMG
TMP_SIZE='24m'
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

sleep 9

# make finder deal look nice
echo '
  tell application "Finder"
    tell disk "'nanobox'"
      open
      delay 5
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
  -o "nanobox.dmg"

# Set icon on .dmg
sips -i resources/nanodesk.icns
derez -only icns resources/nanodesk.icns > nanodesk.rsrc
rez -append nanodesk.rsrc -o nanobox.dmg
setfile -a C nanobox.dmg

# cleanup temp things
rm -f temp.dmg
rm -f nanodesk.rsrc
