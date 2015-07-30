#!/usr/bin/env bash

#----------------------------------------------------------------------
# Functions
#----------------------------------------------------------------------
# Exits the script with the given exit code after waiting
# for a keypress.
#
# @param [Integer] $1 exit code.
function key_exit() {
    echo "Press any key to exit."
    read
    exit $1
}

# Appends a value to an array.
#
# @param [String] $1 Name of the variable to modify
# @param [String] $2 Value to append
function append() {
    eval $1[\${#$1[*]}]=$2
}

#----------------------------------------------------------------------
# Script
#----------------------------------------------------------------------
# Collect the directories and files to remove
my_files=()
append my_files "/opt/nanobox"
append my_files "/usr/local/bin/nanobox"

# Print the files and directories that are to be removed and verify
# with the user that that is what he/she really wants to do.
echo "The following files and directories will be removed:"
for file in "${my_files[@]}"; do
    echo "    $file"
done

echo ""
echo "'bundle' includes Vagrant and VirtualBox"
echo "'nanobox' includes nanobox binary and Vagrant box"
echo "What would you like to uninstall (bundle/nanobox)?"
read my_answer
if [ "$my_answer" != "bundle" ] && [ "$my_answer" != "nanobox" ]; then
    echo "Aborting install. (answer: ${my_answer})"
    key_exit 2
fi

# Initiate the actual uninstall, which requires admin privileges.
echo "The uninstallation process requires administrative privileges"
echo "because some of the installed files cannot be removed by a"
echo "normal user. You may now be prompted for a password..."
echo ""

# Use AppleScript so we can use a graphical `sudo` prompt.
# This way, people can enter the username they wish to use
# for sudo, and it is more Apple-like.
osascript -e "do shell script \"/bin/rm -Rf ${my_files[*]}\" with administrator privileges"

# Verify that the uninstall succeeded by checking whether every file
# we meant to remove is actually removed.
for file in "${my_files[@]}"; do
    if [ -e "${file}" ]; then
        echo "An error must have occurred since a file that was supposed to be"
        echo "removed still exists: ${file}"
        echo ""
        echo "Please try again."
        key_exit 1
    fi
done

vagrant box list  | grep '^nanobox/boot2docker ' &> /dev/null
if [[ $? -eq 0 ]]; then
    vagrant box remove nanobox/boot2docker --force
fi

echo "Successfully uninstalled nanobox."

# Run the uninstall.tool scripts of vagrant and virtualbox also (if selected)
if [ "$my_answer" == "bundle" ]; then
    echo "Uninstalling vagrant.."
    which vagrant
    if [[ $? -eq 0 ]]; then
        hdiutil mount /Volumes/nanobox/.vagrant.dmg
        sudo /Volumes/Vagrant/uninstall.tool
        hdiutil unmount /Volumes/Vagrant
    fi
    
    echo "Uninstalling virtualbox.."
    which vboxmanage
    if [[ $? -eq 0 ]]; then
        hdiutil mount /Volumes/nanobox/.virtualbox.dmg
        sudo /Volumes/VirtualBox/VirtualBox_Uninstall.tool
        hdiutil unmount /Volumes/VirtualBox/
    fi
fi

echo "Done."
key_exit 0
