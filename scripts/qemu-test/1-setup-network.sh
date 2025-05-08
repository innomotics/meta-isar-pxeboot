#! /bin/bash
#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

echo "Setup network..."

SCRIPT_DIR=$( dirname -- "$( readlink -f -- "$0"; )"; )
. ${SCRIPT_DIR}/env.sh
. ${SCRIPT_DIR}/lib.sh

###########
# Precheck
###########

# checks before we even start (all utils installed, ports available, ...)
echo "Precheck..."

program_installed brctl bridge-utils
program_installed tunctl uml-utilities

echo "Precheck successful"

brctl addbr ${BR_IFNAME}
tunctl -t ${TAP_IFNAME_PXE_SERVER} -u $(whoami)
brctl addif ${BR_IFNAME} ${TAP_IFNAME_PXE_SERVER}

tunctl -t ${TAP_IFNAME_PXE_TARGET} -u $(whoami)
brctl addif ${BR_IFNAME} ${TAP_IFNAME_PXE_TARGET}

# TODO: set ip of bridge?
ip link set dev ${BR_IFNAME} up
ip link set dev ${TAP_IFNAME_PXE_SERVER} up
ip link set dev ${TAP_IFNAME_PXE_TARGET} up

echo "Network setup successfully."
