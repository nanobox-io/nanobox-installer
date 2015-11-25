#!/bin/bash -e

# Fetch installers
# nanobox
cp nanobox.deb nanobox-bundle/nanobox.deb

# virtualbox
if ! [ -a nanobox-bundle/virtualbox.deb ]; then
  wget -O nanobox-bundle/virtualbox.deb http://download.virtualbox.org/virtualbox/5.0.10/virtualbox-5.0_5.0.10-104061~Ubuntu~trusty_amd64.deb
fi

# vagrant
if ! [ -a nanobox-bundle/vagrant.deb ]; then
  wget -O nanobox-bundle/vagrant.deb https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.4_x86_64.deb
fi

# proper permissions
chmod 644 nanobox-bundle/virtualbox.deb
chmod 644 nanobox-bundle/vagrant.deb

chmod 755 nanobox-bundle/install
chmod 755 nanobox-bundle/uninstall

# build package
tar -czf nanobox-bundle.tgz nanobox-bundle/.
