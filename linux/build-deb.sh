mkdir -p nanobox/DEBIAN
mkdir -p nanobox/opt/nanobox/bin
mkdir -p nanobox/opt/nanobox/share
mkdir -p nanobox/usr/share/man/man1
mkdir -p nanobox/usr/share/doc/nanobox

NANOBOX_VERS="0.0.7"
BOOT2DOCKER_VERS="0.0.7"

if ! [ -x nanobox/opt/nanobox/bin/nanobox ]; then
  wget -O nanobox/opt/nanobox/bin/nanobox https://s3.amazonaws.com/tools.nanobox.io/cli/linux/amd64/nanobox
  chmod 755 nanobox/opt/nanobox/bin/nanobox
fi

if ! [ -a nanobox/opt/nanobox/share/nanobox-boot2docker.box ]; then
  wget -O nanobox/opt/nanobox/share/nanobox-boot2docker.box https://github.com/pagodabox/nanobox-boot2docker/releases/download/v$(BOOT2DOCKER_VERS)/nanobox-boot2docker.box
fi

# create control file
cat > nanobox/DEBIAN/control <<-EOF
Package: nanobox
Version: $NANOBOX_VERS
Section: base
Priority: optional
Architecture: all
Depends: vagrant, virtualbox
Maintainer: Steve Domino <sdomino@pagodabox.com>
Description: Nanobox cli utility
 This tool provides a simple, quick dev environment.
EOF

# create postinstall file (for docs?)
cat > nanobox/DEBIAN/postinst <<-'EOF'
#!/bin/sh -e
# Automatically added by dh_installdocs
if [ "$1" = "configure" ]; then
  if [ -d /usr/doc -a ! -e /usr/doc/nanobox -a -d /usr/share/doc/nanobox ]; then
    ln -sf ../share/doc/nanobox /usr/doc/nanobox
  fi
# End automatically added section

  ln -sf /opt/nanobox/bin/nanobox /usr/local/bin/nanobox
  which vagrant > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    vagrant box add --force --name nanobox/boot2docker /opt/nanobox/share/nanobox-boot2docker.box > /dev/null 2>&1
  fi
fi
EOF

# create pre-removal file (for docs?)
cat > nanobox/DEBIAN/prerm <<-'EOF'
#!/bin/sh -e
if [ "$1" = "upgrade" -o "$1" = "remove" ]; then
  rm -f /usr/local/bin/nanobox
  vagrant box list | grep '^nanobox/boot2docker ' && vagrant box remove nanobox/boot2docker --force > /dev/null 2>&1 || true

  if [ -L /usr/doc/nanobox ]; then
    rm -f /usr/doc/nanobox
  fi
fi
EOF

chmod 755 nanobox/DEBIAN/p*

# create copyright file
cat > nanobox/usr/share/doc/nanobox/copyright <<-EOF
nanobox

Copyright 2015: Pagoda Box
nanobox.io

Mozilla Public License, version 2.0
EOF

# create changelog file
cat >> nanobox/usr/share/doc/nanobox/changelog <<-EOF
nanobox $NANOBOX_VERS
  * Created package
 -- Pagoda Box 2015
EOF

# create manpage
cat > nanobox/usr/share/man/man1/nanobox.1 <<-EOF
.TH NANOBOX 1 "`date +"%d %b %Y"`" "$NANOBOX_VERS"
.SH NAME
nanobox \- nanobox command line utility

                                     ***
                                  *********
                             *******************
                         ***************************
                             *******************
                         ...      *********      ...
                             ...     ***     ...
                         +++      ...   ...      +++
                             +++     ...     +++
                         \\\\\\      +++   +++      ///
                             \\\\\\     +++     ///
                                  \\\\     //
                                     \\//

                      _  _ ____ _  _ ____ ___  ____ _  _
                      |\\ | |__| |\\ | |  | |__) |  |  \\/
                      | \\| |  | | \\| |__| |__) |__| _/\\_


.SH SYNOPSIS
nanobox <COMMAND> [--debug]

.SH DESCRIPTION
Welcome to the nanobox CLI! This will be your primary tool when working with
nanobox. If you encounter any issues or have any suggestions, find us on
IRC (freenode) at #nanobox. Our engineers are available between 8 - 5pm MST.

All commands have a short [-*] and a verbose [--*] option when passing flags.

You can pass -h, --help, or help to any command to receive detailed information
about that command.

You can pass --debug at the end of any command to see all request/response
output when making API calls.

.SH OPTIONS
-h, --help, help
  Run anytime to receive detailed information about a command.

-v, --version, version
  Run anytime to see the current version of the CLI.

--debug
  Shows all API request/response output. MUST APPEAR LAST

.SH COMMANDS
.IP "create      : Runs an 'init' and starts a nanobox VM"
.IP "deploy      : Deploys to your nanobox VM"
.IP "destroy     : Destroys the current nanobox VM"
.IP "halt        : Halts the current nanobox VM"
.IP "help        : Display this help"
.IP "init        : Creates a nanobox flavored Vagrantfile"
.IP "log         : Show/Stream nanobox logs"
.IP "new         : Create a new nanobox developer project"
.IP "publish     : Publish your nanobox live"
.IP "reload      :"
.IP "resume      : Resumes a halted/suspened nanobox VM"
.IP "status      : Display all current nanobox VM's"
.IP "suspend     : Suspends the current nanobox VM"
.IP "up          : Runs a 'create' and a 'deploy'"
.IP "update      : Updates this CLI to the newest version"

EOF

# gzip manpage
gzip --best nanobox/usr/share/man/man1/nanobox.1
# build package
dpkg-deb --build nanobox
# rename package
mv nanobox.deb nanobox-$(NANOBOX_VERS).deb
