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
#

CURRENT_DIR=$(pwd)
export CURRENT_DIR

readonly SERVICE="openvswitch"
RESULT=$(pgrep $SERVICE)
readonly RESULT
readonly OVS_PMD_STAT_SCRIPT=$CURRENT_DIR/ovs_pmd_stats/ovs_pmd_stats.py
readonly PATH_LOCAL=/usr/local/src/

if [ "${RESULT:-null}" != null ]; then
  echo "Openvswitch service is running."
  sudo ovs-vsctl set-manager ptcp:6640
  cp "$OVS_PMD_STAT_SCRIPT" $PATH_LOCAL
else
  echo "Openvswitch service is not running. Please start before running ovs plugins"
fi
# Always copy python ovs module when building Docker image
if [ "$DOCKER" == "y" ]; then
  cp "$OVS_PMD_STAT_SCRIPT" $PATH_LOCAL
fi
