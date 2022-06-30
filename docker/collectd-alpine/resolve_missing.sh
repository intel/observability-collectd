#!/bin/bash

set -o pipefail
set -eux

# shellcheck disable=SC2046
# Resolve missing dependencies for plugins and install required packages:
# (1) run ldd for each *.so file to get dependencies per plugin
# (2) grep the result to get only missing libraries
# (3) use awk to extract the library name from each line
# (4) search the repository for packages containing the libraries
# (5) use sed to remove the version from package name
# (6) install the packages
# /--------(6)-------\/----(4)----\/------------------------------(1)-------------------------------\
#  /---------------(2)--------------\/----------------(3)-----------------\/----------(5)-----------\
apk add --no-cache $(apk search $(find /opt/collectd/lib/collectd/*.so -type f -exec ldd {} \; 2>&1 | \
    grep "No such file or directory" | awk '{ sub(/:$/,"",$5); print $5 }') | sed 's/-[0-9]\+\..*$//' | sort)
