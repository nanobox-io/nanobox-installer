#!/bin/bash -x

# cleanup from a previous build
[ -f nanobox-micro.dmg ] && rm -f nanobox-micro.dmg
[ -f dmg/nanobox.pkg ] && rm -f dmg/nanobox.pkg
[ -f nanobox/bin/nanobox ] && rm -f nanobox/bin/nanobox
[ -f dmg/.virtualbox.dmg ] && rm -f dmg/.virtualbox.dmg
[ -f dmg/.vagrant.dmg ] && rm -f dmg/.vagrant.dmg
[ -f dmg/.nanobox-boot2docker.box ] && rm -f dmg/.nanobox-boot2docker.box

# prep dirs
mkdir -p \
  dmg/.support \
  nanobox/bin

# get mac bins
# nanobox
curl -fLkso dmg/nanobox 'https://s3.amazonaws.com/tools.nanobox.io/cli/darwin/amd64/nanobox'
chmod 755 dmg/nanobox

sips -i resources/nanodesk.icns
derez -only icns resources/nanodesk.icns > nanodesk.rsrc
rez -append nanodesk.rsrc -o dmg/nanobox
setfile -a C dmg/nanobox

#########################################################
#   DMG
#########################################################
# create temporary DMG
TMP_SIZE='15m'
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
      delay 20
      set current view of container window to icon view
      set toolbar visible of container window to false
      set statusbar visible of container window to false
      set the bounds of container window to {400, 100, 885, 430}
      set theViewOptions to the icon view options of container window
      set arrangement of theViewOptions to not arranged
      set icon size of theViewOptions to 72

      delay 9
      set background picture of theViewOptions to file ".support:'background.png'"
      delay 9

      make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
      set position of item "'nanobox'" of container window to {100, 100}
      set position of item "'Applications'" of container window to {375, 100}
      delay 5

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
  -o "nanobox-micro.dmg"

# Set icon on .dmg
sips -i resources/nanodesk.icns
derez -only icns resources/nanodesk.icns > nanodesk.rsrc
rez -append nanodesk.rsrc -o nanobox-micro.dmg
setfile -a C nanobox-micro.dmg

# cleanup temp things
rm -f temp.dmg
rm -f nanodesk.rsrc
