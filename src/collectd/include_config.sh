#!/bin/bash
# Copyright 2017-2021 Intel Corporation and OPNFV. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Config file options are changing between releases so we have to store both
# configurations variants and choose correct one for target collectd version
#

if [ -z "$1" ]; then
    echo "Error! Please sample configs variant name as a param!"\
         "(name of directory with sample-configs)"
    echo "Usage:"
    echo "$0 COLLECTD_CONFIGS_VARIANT_NAME [COLLECTD_PREFIX]"
    echo "e.g. $0 'sample_configs-stable' '/opt/collectd'"
    exit 1
fi

COLLECTD_PREFIX="/opt/collectd"
if [ -n "$2" ]; then
    COLLECTD_PREFIX="$2"
    echo "Using user defined path for collectd files: '$COLLECTD_PREFIX'"
else
    echo "Using default path for collectd files: '/opt/collectd'"
fi

readonly SAMPLE_CONF_VARIANT="$1"
readonly COLLECTD_CONF_FILE=$COLLECTD_PREFIX/etc/collectd.conf
readonly COLLECTD_CONF_DIR=$COLLECTD_PREFIX/etc/collectd.conf.d
readonly INCLUDE_CONF="<Include \"$COLLECTD_PREFIX/etc/collectd.conf.d\">"
CURR_DIR=$(pwd)
readonly CURR_DIR
HOSTNAME=$(hostname)
readonly HOSTNAME
readonly SAMPLE_CONF_DIR=$CURR_DIR/$SAMPLE_CONF_VARIANT

if [ ! -d "$SAMPLE_CONF_DIR" ]; then
    echo "$SAMPLE_CONF_DIR does not exits!"\
         "Probably passed bad variant name as a param: $SAMPLE_CONF_VARIANT"
    exit 1
fi

if [ "$DOCKER" == "y" ]; then
    cp "$CURR_DIR"/collectd.conf "$COLLECTD_CONF_FILE"
fi

function write_include {
    echo "Hostname \"$HOSTNAME\"" | sudo tee -a "$COLLECTD_CONF_FILE";
    echo "$INCLUDE_CONF" | sudo tee -a "$COLLECTD_CONF_FILE";
    echo "  Filter \"*.conf\"" | sudo tee -a "$COLLECTD_CONF_FILE";
    echo -e "</Include>" | sudo tee -a "$COLLECTD_CONF_FILE";
}

if ! grep -qe "<Include \"$COLLECTD_PREFIX/etc/collectd.conf.d\">" "$COLLECTD_CONF_FILE"; then
    write_include
fi

mkdir -p "$COLLECTD_CONF_DIR"

SAMPLE_CONF_FILES="$SAMPLE_CONF_DIR/*"
for F in $SAMPLE_CONF_FILES; do
    FILE=$(basename "$F")
    if [ -f "$COLLECTD_CONF_DIR"/"$FILE" ]; then
        echo "File $COLLECTD_CONF_DIR/$FILE exists"
    else
        cp "$F" "$COLLECTD_CONF_DIR"
    fi
done
