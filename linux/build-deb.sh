mkdir -p nanobox/DEBIAN
mkdir -p nanobox/usr/local/bin
mkdir -p nanobox/usr/share/man/man1
mkdir -p nanobox/usr/share/doc/nanobox

wget -O nanobox/usr/local/bin/nanobox https://s3.amazonaws.com/tools.nanobox.io/cli/linux/amd64/nanobox
chmod 755 nanobox/usr/local/bin/nanobox

# create control file
cat > debian/DEBIAN/control <<-EOF
Package: nanobox
Version: 0.0.7
Section: base
Priority: optional
Architecture: all
Depends: vagrant, virtualbox
Maintainer: Steve Domino <sdomino@pagodabox.com>
Description: Nanobox cli utility
 This tool provides a simple, quick dev environment.
EOF

# create postinstall file (for docs?)
cat > nanobox/nanobox/postinst <<-'EOF'
#!/bin/sh
set -e
# Automatically added by dh_installdocs
if [ "$1" = "configure" ]; then
  if [ -d /usr/doc -a ! -e /usr/doc/nanobox -a -d /usr/share/doc/nanobox ]; then
    ln -sf ../share/doc/nanobox /usr/doc/nanobox
  fi
fi
# End automatically added section
EOF

# create pre-removal file (for docs?)
cat > nanobox/nanobox/prerm <<-'EOF'
#!/bin/sh
set -e
# Automatically added by dh_installdocs
if [ \( "$1" = "upgrade" -o "$1" = "remove" \) -a -L /usr/doc/nanobox ]; then
  rm -f /usr/doc/nanobox
fi
# End automatically added section
EOF

chmod 755 nanobox/nanobox/p*

# create copyright file
cat > nanobox/usr/share/doc/nanobox/copyright <<-EOF
nanobox

Copyright 2015: Pagoda Box
nanobox.io

Mozilla Public License, version 2.0
EOF

# create changelog file
cat > nanobox/usr/share/doc/nanobox/changelog <<-EOF
nanobox 0.0.7
  * Created package
 -- Pagoda Box 2015
EOF

# create manpage
cat > nanobox/usr/share/man/man1/nanobox.1 <<-EOF

                                     ***
                                  *********
                             *******************
                         ***************************
                             *******************
                         ...      *********      ...
                             ...     ***     ...
                         +++      ...   ...      +++
                             +++     ...     +++
                         \\\      +++   +++      ///
                             \\\     +++     ///
                                  \\     //
                                     \//

                      _  _ ____ _  _ ____ ___  ____ _  _
                      |\ | |__| |\ | |  | |__) |  |  \/
                      | \| |  | | \| |__| |__) |__| _/\_



Description:
  Welcome to the nanobox CLI! This will be your primary tool when working with
  nanobox. If you encounter any issues or have any suggestions, find us on
  IRC (freenode) at #nanobox. Our engineers are available between 8 - 5pm MST.

  All commands have a short [-*] and a verbose [--*] option when passing flags.

  You can pass -h, --help, or help to any command to receive detailed information
  about that command.

  You can pass --debug at the end of any command to see all request/response
  output when making API calls.

Usage:
  pagoda (<COMMAND>:<ACTION> OR <ALIAS>) [GLOBAL FLAG] <POSITIONAL> [SUB FLAGS] [--debug]

Options:
  -h, --help, help
    Run anytime to receive detailed information about a command.

  -v, --version, version
    Run anytime to see the current version of the CLI.

  --debug
    Shows all API request/response output. MUST APPEAR LAST

Available Commands:

  create      : Runs an 'init' and starts a nanobox VM
  deploy      : Deploys to your nanobox VM
  destroy     : Destroys the current nanobox VM
  halt        : Halts the current nanobox VM
  help        : Display this help
  init        : Creates a nanobox flavored Vagrantfile
  log         : Show/Stream nanobox logs
  new         : Create a new nanobox developer project
  publish     : Publish your nanobox live
  reload      :
  resume      : Resumes a halted/suspened nanobox VM
  status      : Display all current nanobox VM's
  suspend     : Suspends the current nanobox VM
  up          : Runs a 'create' and a 'deploy'
  update      : Updates this CLI to the newest version
  
EOF

# gzip manpage
gzip --best nanobox/usr/share/man/man1/nanobox.1
# build package
dpkg-deb --build nanobox
# rename package
mv nanobox.deb nanobox-0.0.7.deb
