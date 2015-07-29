#!/bin/bash -x

# cleanup from a previous build
[ -f nanobox.dmg ] && rm -f nanobox.dmg
[ -f dmg/nanobox.pkg ] && rm -f dmg/nanobox.pkg
[ -f nanobox/bin/nanobox ] && rm -f nanobox/bin/nanobox

# prep dirs
mkdir -p \
  dmg/.support \
  nanobox/bin

# prep assets
# combine all 3 licences into the one tos/license.html
[ -f resources/background.png ] || curl -fLkso resources/background.png http://troyr.com/wp-content/uploads/2011/03/pink-pagoda-logo-stacked.png
# replace with nanobox background
[ -f dmg/.support/background.png ] || curl -fLkso dmg/.support/background.png http://c8.alamy.com/comp/ADW0EH/new-mega-box-shopping-mall-in-hong-kong-2007-ADW0EH.jpg

# get mac bins
# nanobox
curl -fLkso nanobox/bin/nanobox 'https://s3.amazonaws.com/tools.nanobox.io/cli/darwin/amd64/nanobox'
chmod 755 nanobox/bin/nanobox
# virtualbox
[ -f dmg/.virtualbox.dmg ] || curl -fLkso dmg/.virtualbox.dmg 'http://download.virtualbox.org/virtualbox/5.0.0/VirtualBox-5.0.0-101573-OSX.dmg'
# vagrant
[ -f dmg/.vagrant.dmg ] || curl -fLkso dmg/.vagrant.dmg 'https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.3.dmg'
# boot2docker box
[ -f dmg/.nanobox-boot2docker.box ] || curl -fLkso dmg/.nanobox-boot2docker.box https://github.com/pagodabox/nanobox-boot2docker/releases/download/v0.0.7/nanobox-boot2docker.box


set -e
#########################################################
#   PKG
#########################################################
# build core.pkg
pkgbuild \
  --root nanobox \
  --identifier com.nanobox.nanobox \
  --version "0.0.7" \
  --install-location "/opt/nanobox" \
  --scripts "scripts" \
  --timestamp=none \
  core.pkg

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
TMP_SIZE='256m'
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

# make finder deal look nice
echo '
  tell application "Finder"
    tell disk "'nanobox'"
      open
      set current view of container window to icon view
      set toolbar visible of container window to false
      set statusbar visible of container window to false
      set the bounds of container window to {100, 100, 710, 515}
      set theViewOptions to the icon view options of container window
      set arrangement of theViewOptions to not arranged
      set icon size of theViewOptions to 72
      delay 2
      set background picture of theViewOptions to file ".support:'background.png'"
      delay 5
      set position of item "'nanobox.pkg'" of container window to {465, 145}
      update without registering applications
      delay 5
    end tell
  end tell
' | osascript

# set the permissions and generate the final DMG
chmod -Rf go-w /Volumes/nanobox
sync
hdiutil detach ${DEVICE}

hdiutil convert \
  "temp.dmg" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "nanobox.dmg"

# cleanup temp things
rm -f temp.dmg