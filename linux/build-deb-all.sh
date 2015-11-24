#!/bin/bash -e
mkdir -p nanobox-bundle/opt/nanobox/share
VAGRANT_VERS="1.7.4"
VIRTUALBOX_VERS="5.0.8"

# Fetch installers
# nanobox
cp nanobox.deb nanobox-bundle/opt/nanobox/share/nanobox.deb

# virtualbox
if ! [ -a nanobox-bundle/opt/nanobox/share/virtualbox.deb ]; then
  wget -O nanobox-bundle/opt/nanobox/share/virtualbox.deb http://download.virtualbox.org/virtualbox/5.0.10/virtualbox-5.0_5.0.10-104061~Ubuntu~trusty_amd64.deb
fi
# vagrant
if ! [ -a nanobox-bundle/opt/nanobox/share/vagrant.deb ]; then
  wget -O nanobox-bundle/opt/nanobox/share/vagrant.deb https://dl.bintray.com/mitchellh/vagrant/vagrant_${VAGRANT_VERS}_x86_64.deb
fi

# gzip docs
[ -f nanobox-bundle/usr/share/doc/nanobox-bundle/changelog ] && gzip -n --best nanobox-bundle/usr/share/doc/nanobox-bundle/changelog || true

# proper permissions
chmod 644 nanobox-bundle/opt/nanobox/share/virtualbox.deb
chmod 644 nanobox-bundle/opt/nanobox/share/vagrant.deb

chmod 644 nanobox-bundle/usr/share/doc/nanobox-bundle/changelog.gz
chmod 644 nanobox-bundle/usr/share/doc/nanobox-bundle/copyright

find nanobox-bundle -type d | xargs chmod 755
chmod 755 nanobox-bundle/DEBIAN/p*

# build package
fakeroot dpkg-deb --build nanobox-bundle
