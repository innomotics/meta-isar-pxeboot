#
# Copyright (c) Siemens AG, 2024
#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit image

ISAR_RELEASE_CMD = "git -C ${LAYERDIR_meta-isar-pxeboot} describe --tags --dirty --always --match 'v[0-9].[0-9]*'"
DESCRIPTION = "PXE Boot VM used to bootstrap online installer"

IMAGE_FULLNAME .= "-${PXE_TARGET_MACHINE}"
ROOTFS_PACKAGE_SUFFIX = "${IMAGE_FULLNAME}"

IMAGE_INSTALL += "pxe-setup"
IMAGE_INSTALL:append:pxe-nfsroot = " nfs-installer-rootfs"

FILESEXTRAPATHS:prepend := "${THISDIR}:"


IMAGE_PREINSTALL += " \
    bash-completion less vim nano"

# Nice to have packages (debug)
IMAGE_PREINSTALL += " \
    iproute2 iputils-ping procps"

require ${@bb.utils.contains('ENABLE_ROOT_USER_PXE_SERVER', '1', 'user-setup-root.inc', '', d)}

CUSTOMIZATIONS += "hostname"
