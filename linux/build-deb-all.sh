mkdir -p nanobox-bundle/opt/nanobox/share
VAGRANT_VERS="1.7.3"
VIRTUALBOX_VERS="5.0.0"

# Fetch installers
# nanobox
cp nanobox.deb nanobox-bundle/opt/nanobox/share/nanobox.deb

# virtualbox
if ! [ -a nanobox-bundle/opt/nanobox/share/virtualbox.deb ]; then
  wget -O nanobox-bundle/opt/nanobox/share/virtualbox.deb http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERS}/virtualbox-5.0_${VIRTUALBOX_VERS}-101573~Ubuntu~trusty_amd64.deb
fi
# vagrant
if ! [ -a nanobox-bundle/opt/nanobox/share/vagrant.deb ]; then
  wget -O nanobox-bundle/opt/nanobox/share/vagrant.deb https://dl.bintray.com/mitchellh/vagrant/vagrant_${VAGRANT_VERS}_x86_64.deb
fi

chmod 644 nanobox-bundle/opt/nanobox/share/virtualbox.deb
chmod 644 nanobox-bundle/opt/nanobox/share/vagrant.deb

find nanobox-bundle -type d | xargs chmod 755

# build package
fakeroot dpkg-deb --build nanobox-bundle
