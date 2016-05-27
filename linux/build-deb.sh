#!/bin/bash -e
mkdir -p nanobox/opt/nanobox/bin

if [ -f beta/nanobox-linux ]; then
  cp beta/nanobox-linux nanobox/opt/nanobox/bin/nanobox
else
  wget -O nanobox/opt/nanobox/bin/nanobox https://s3.amazonaws.com/tools.nanobox.io/cli/linux/amd64/nanobox
fi

chmod 755 nanobox/opt/nanobox/bin/nanobox

# gzip docs
[ -f nanobox/usr/share/man/man1/nanobox.1 ] && gzip -n --best nanobox/usr/share/man/man1/nanobox.1 || true
[ -f nanobox/usr/share/doc/nanobox/changelog ] && gzip -n --best nanobox/usr/share/doc/nanobox/changelog || true

# proper permissions
chmod 644 nanobox/usr/share/man/man1/nanobox.1.gz
chmod 644 nanobox/usr/share/doc/nanobox/changelog.gz
chmod 644 nanobox/usr/share/doc/nanobox/copyright

find nanobox -type d | xargs chmod 755
chmod 755 nanobox/DEBIAN/p*

# build package
fakeroot dpkg-deb --build nanobox
