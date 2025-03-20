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

IMAGE_INSTALL += "pxe-setup"
IMAGE_INSTALL:append:pxe-nfsroot = " nfs-installer-rootfs"

# Set root password to 'root'
# Password was encrypted using following command:
#   mkpasswd -m sha512crypt -R 10000
# mkpasswd is part of the 'whois' package of Debian
USERS += "root"
USER_root[password] ??= "$6$rounds=10000$RXeWrnFmkY$DtuS/OmsAS2cCEDo0BF5qQsizIrq6jPgXnwv3PHqREJeKd1sXdHX/ayQtuQWVDHe0KIO0/sVH8dvQm1KthF0d/"
USER_root[shell] = "/bin/bash"

FILESEXTRAPATHS:prepend := "${THISDIR}:"


IMAGE_PREINSTALL += " \
    bash-completion less vim nano"

# Nice to have packages (debug)
IMAGE_PREINSTALL += " \
    iproute2 iputils-ping procps"