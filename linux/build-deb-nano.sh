mkdir -p nanobox-nano/opt/nanobox/bin

wget -O nanobox-nano/opt/nanobox/bin/nanobox https://s3.amazonaws.com/tools.nanobox.io/cli/linux/amd64/nanobox
chmod 755 nanobox-nano/opt/nanobox/bin/nanobox

# gzip docs
gzip --best nanobox-nano/usr/share/man/man1/nanobox.1
gzip --best nanobox-nano/usr/share/doc/nanobox/changelog

chmod 644 nanobox-nano/usr/share/man/man1/nanobox.1.gz
chmod 644 nanobox-nano/usr/share/doc/nanobox/changelog.gz

find nanobox-nano -type d | xargs chmod 755
# build package
fakeroot dpkg-deb --build nanobox-nano
