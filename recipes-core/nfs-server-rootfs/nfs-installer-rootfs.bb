#
# Copyright (c) Siemens AG, 2025
# Copyright (c) Innomotics GmbH, 2025
#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

DESCRIPTION = "NFS Server setup to serve online installer rootfs."
MAINTAINER = "Alexander Heinisch <alexander.heinisch@siemens.com>"

DEBIAN_DEPENDS += "nfs-kernel-server, tar"

SRC_URI = " \
    file://postinst \
    "

PXESERVER_MC ??= "pxe-boot-server"
PXESERVER_LIVE_INSTALLER_MC ??= "isar-installer"
PXESERVER_LIVE_INSTALLER_DISTRO ??= "${DISTRO}"
PXESERVER_LIVE_INSTALLER_MACHINE ??= "${MACHINE}"
PXESERVER_LIVE_INSTALLER_IMAGE ??= "isar-image-installer"

PXESERVER_LIVE_INSTALLER_TMPDIR ??= "${TOPDIR}/tmp"
PXESERVER_LIVE_INSTALLER_DEPLOY_DIR ??= "${PXESERVER_LIVE_INSTALLER_TMPDIR}/deploy"
PXESERVER_LIVE_INSTALLER_DEPLOY_DIR_IMAGE ??= "${PXESERVER_LIVE_INSTALLER_DEPLOY_DIR}/images/${PXESERVER_LIVE_INSTALLER_MACHINE}"
PXESERVER_LIVE_INSTALLER_FILE_NAME ??= "${PXESERVER_LIVE_INSTALLER_IMAGE}-${PXESERVER_LIVE_INSTALLER_DISTRO}-${PXESERVER_LIVE_INSTALLER_MACHINE}"

do_install[mcdepends] = "mc:${PXESERVER_MC}:${PXESERVER_LIVE_INSTALLER_MC}:${PXESERVER_LIVE_INSTALLER_IMAGE}:do_image_tar"
do_install[cleandirs] = " \
	${D}/var/installer/rootfs/ \
	${D}/var/installer/data/ \
	"
do_install() {
    install -v -m 644 ${PXESERVER_LIVE_INSTALLER_DEPLOY_DIR_IMAGE}/${PXESERVER_LIVE_INSTALLER_FILE_NAME}.tar ${D}/var/installer/rootfs.tar
}