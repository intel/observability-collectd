#!/bin/bash
#
# Install dependencies for the host system
#

readonly ROOT_UID=0
SUDO=""

# function to log message and exit with error code 1
function logexit() {
    echo "$1"
    exit 1
}

# Detect OS name and version from systemd based os-release file
. /etc/os-release

# Get OS name (the First word from $NAME in /etc/os-release)
OS_NAME="$ID"
# Get major version number
OS_VERSION="${VERSION_ID%%.*}"

# check if root
if [ "$UID" -ne "$ROOT_UID" ]
then
    # installation must be run via sudo
    SUDO="sudo -E"
fi

# If there is version specific dir available then set distro_dir to that
distro_dir="$OS_NAME/$OS_VERSION"

# Install dependencies for base system using OS specific scripts
if [ -d "$distro_dir" ] && [ -e "$distro_dir/install.sh" ]; then
    $SUDO "$distro_dir/install.sh" || logexit "$distro_dir/install.sh failed"
else
    logexit "$distro_dir is not supported"
fi
