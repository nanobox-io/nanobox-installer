mkdir -p nanobox/opt/nanobox/bin
mkdir -p nanobox/opt/nanobox/share

wget -O nanobox/opt/nanobox/bin/nanobox https://s3.amazonaws.com/tools.nanobox.io/cli/linux/amd64/nanobox
chmod 755 nanobox/opt/nanobox/bin/nanobox

wget -O nanobox/opt/nanobox/share/nanobox-boot2docker.box https://s3.amazonaws.com/tools.nanobox.io/boxes/vagrant/nanobox-boot2docker.box

# gzip docs
gzip --best nanobox/usr/share/man/man1/nanobox.1
gzip --best nanobox/usr/share/doc/nanobox/changelog

chmod 644 nanobox/usr/share/man/man1/nanobox.1.gz
chmod 644 nanobox/usr/share/doc/nanobox/changelog.gz

find nanobox -type d | xargs chmod 755
# build package
fakeroot dpkg-deb --build nanobox
