#! /bin/bash
#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

echo "Remove network..."

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

brctl delif ${BR_IFNAME} ${TAP_IFNAME_PXE_SERVER}
tunctl -d ${TAP_IFNAME_PXE_SERVER}

brctl delif ${BR_IFNAME} ${TAP_IFNAME_PXE_TARGET}
tunctl -d ${TAP_IFNAME_PXE_TARGET}

brctl delbr ${BR_IFNAME}

echo "Network removed successfully."
