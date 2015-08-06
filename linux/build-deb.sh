mkdir -p nanobox/opt/nanobox/bin
mkdir -p nanobox/opt/nanobox/share

NANOBOX_VERS="0.0.7"
BOOT2DOCKER_VERS="0.0.7"

if ! [ -x nanobox/opt/nanobox/bin/nanobox ]; then
  wget -O nanobox/opt/nanobox/bin/nanobox https://s3.amazonaws.com/tools.nanobox.io/cli/linux/amd64/nanobox
  chmod 755 nanobox/opt/nanobox/bin/nanobox
fi

if ! [ -a nanobox/opt/nanobox/share/nanobox-boot2docker.box ]; then
  wget -O nanobox/opt/nanobox/share/nanobox-boot2docker.box https://github.com/pagodabox/nanobox-boot2docker/releases/download/v${BOOT2DOCKER_VERS}/nanobox-boot2docker.box
fi

# gzip manpage
gzip --best nanobox/usr/share/man/man1/nanobox.1
# build package
dpkg-deb --build nanobox
