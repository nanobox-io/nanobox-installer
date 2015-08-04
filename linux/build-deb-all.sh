mkdir -p nanobox-bundle/opt/nanobox/share
NANOBOX_VERS="0.0.7"
VAGRANT_VERS="1.7.3"
VIRTUALBOX_VERS="5.0.0"

# Fetch installers
# nanobox
cp nanobox-${NANOBOX_VERS}.deb nanobox-bundle/opt/nanobox/share/nanobox.deb

# virtualbox
if ! [ -a nanobox-bundle/opt/nanobox/share/virtualbox.deb ]; then
  wget -O nanobox-bundle/opt/nanobox/share/virtualbox.deb http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERS}/virtualbox-5.0_${VIRTUALBOX_VERS}-101573~Ubuntu~trusty_amd64.deb
fi
# vagrant
if ! [ -a nanobox-bundle/opt/nanobox/share/vagrant.deb ]; then
  wget -O nanobox-bundle/opt/nanobox/share/vagrant.deb https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.3_x86_64.deb
fi

# build package
dpkg-deb --build nanobox-bundle
