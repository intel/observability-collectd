#!/bin/bash
#
# Top level script to build basic setup for the host
#
set -x

readonly ROOT_UID=0
SUDO=""

# function to log message and exit with error code 1
function logexit() {
    echo "$1"
    exit 1
}

if [ "$1" != "-f" ] && [ -d "/opt/collectd" ] || [ -d "/etc/collectd" ]
then
    logexit "collectd is already installed on this system, if you wish to reinstall please rerun the script with a -f argument"
fi

# check if root
if [ "$UID" -ne "$ROOT_UID" ]
then
    # installation must be run via sudo
    SUDO="sudo -E"
fi

if [ -e deps/install.sh ] ; then
    cd deps || logexit "deps does not exist"
    ./install.sh || logexit "failed to install dependencies"
    cd - || logexit ""
else
    logexit "Can not install dependencies"
fi

if [ "$DOCKER" != "y" ]; then
    if [ ! -d /lib/modules/"$(uname -r)"/build ] ; then
        logexit "Kernel devel is not available for active kernel. It can be caused by recent kernel update. Please reboot and run $0 again."
    fi
fi

# download and compile dependencies and Collectd
if [ -f src/Makefile ] ; then
    cd src || logexit "src does not exist"
    make install || logexit "Make install failed"
    cd - || logexit ""
else
    logexit "Make failed; No Makefile"
fi

# configure ovs pmd stats app
if [ -e apps/ovs_pmd_stats_config.sh ] ; then
    cd apps || logexit "apps does not exist"
    $SUDO ./ovs_pmd_stats_config.sh || logexit "failed to run ovs_pmd_stats_config.sh"
    cd - || logexit ""
else
    logexit "Can not configure ovs pmd stats"
fi