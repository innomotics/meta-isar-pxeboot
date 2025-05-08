#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

sim_name="pxe-1"
TAP_IFNAME_PXE_SERVER="${sim_name}-server"
TAP_IFNAME_PXE_TARGET="${sim_name}-target"
BR_IFNAME="${sim_name}-br"


#PXE_SERVER_IMAGE_PATH=${PXE_SERVER_IMAGE_PATH:-build/tmp-pxe-boot-server-qemuamd64/deploy/images/qemuamd64/pxe-boot-server-debian-bookworm-qemuamd64.wic}