#!/bin/bash -x

# dir prep
mkdir -p nanobox/pkg nanobox/bin nanobox/lib

# create installer
cat > nanobox/install.sh <<-'EOF'
#!/bin/bash
VBOX_VERS='5.0.0'
VAGRANT_VERS=1.7.3

which vboxmanage &> /dev/null
if [[ $? -ne 0 ]]; then
  sudo dpkg -i /opt/nanobox/pkg/virtualbox-${VBOX_VERS}-trusty.deb && rm -f /opt/nanobox/pkg/virtualbox-${VBOX_VERS}-trusty.deb
fi

which vagrant &> /dev/null
if [[ $? -ne 0 ]]; then
  sudo dpkg -i /opt/nanobox/pkg/vagrant-${VAGRANT_VERS}.deb && rm -f /opt/nanobox/pkg/vagrant-${VAGRANT_VERS}.deb
fi

which nanobox &> /dev/null
if [[ $? -ne 0 ]]; then
  sudo cp /opt/nanobox/bin/nanobox /usr/local/bin/nanobox
fi

vagrant box list  | grep '^nanobox/boot2docker ' &> /dev/null
if [[ $? -ne 0 ]]; then
  vagrant box add --name nanobox/boot2docker /opt/nanobox/lib/nanobox-boot2docker.box && rm -f /opt/nanobox/lib/nanobox-boot2docker.box
fi
EOF
chmod 755 nanobox/install.sh

# create uninstaller
cat > nanobox/uninstall.sh <<-'EOF'
#!/bin/bash
read choice -p "Are you sure you want to uninstall nanobox, virtualbox, and vagrant (y/N)?"
if [[ "$choice" == "y" ]]; then
  sudo dpkg -r virtualbox
  vagrant box remove nanobox/boot2docker --force
  sudo dpkg -r vagrant
  sudo rm -f /usr/local/bin/nanobox
else
  echo "Aborting uninstallation: $choice"
  exit 2
fi

EOF
chmod 755 nanobox/uninstall.sh

# virtualbox
wget -O nanobox/pkg/virtualbox-5.0.0-trusty.deb http://download.virtualbox.org/virtualbox/5.0.0/virtualbox-5.0_5.0.0-101573~Ubuntu~trusty_amd64.deb

# vagrant
wget -O nanobox/pkg/vagrant-1.7.3.deb https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.3_x86_64.deb

# nanobox-cli
wget -O nanobox/bin/nanobox https://s3.amazonaws.com/tools.nanobox.io/cli/linux/amd64/nanobox
chmod 755 nanobox/bin/nanobox

# boot2docker image
wget -O nanobox/lib/nanobox-boot2docker.box https://s3.amazonaws.com/tools.nanobox.io/boxes/vagrant/nanobox-boot2docker.box

# create fat installer
tar -czf nanobox.tgz nanobox/

# to install - curl xxxxxxxxxx/nanobox.tgz | sudo tar -C /opt -zxf - && sudo /opt/nanobox/install.sh
