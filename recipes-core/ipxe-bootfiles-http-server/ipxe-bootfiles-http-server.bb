#
# Copyright (c) Siemens AG, 2025
#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

DESCRIPTION = "HTTP Server to serve ipxe bootfiles via http"
MAINTAINER = "Alexander Heinisch <alexander.heinisch@siemens.com>"

DEBIAN_DEPENDS += "nginx"

PXESERVER_IP ?= "192.168.148.42"
PXESERVER_LIVE_INSTALLER_ADDITIONAL_KERNEL_CMDLINE ?= ""

TEMPLATE_VARS = "\
    PXESERVER_IP \
    PXESERVER_LIVE_INSTALLER_ADDITIONAL_KERNEL_CMDLINE \
    "

TEMPLATE_FILES = "\
    default.ipxe.tmpl \
    "

SRC_URI = "\
    file://postinst \
    file://etc/ \
    file://default.ipxe.tmpl \
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

do_install[mcdepends] = "mc:${PXESERVER_MC}:${PXESERVER_LIVE_INSTALLER_MC}:${PXESERVER_LIVE_INSTALLER_IMAGE}:do_copy_boot_files"
do_install() {
    install -v -d ${D}/var/installer/bootfiles
    install -v -m 644 ${PXESERVER_LIVE_INSTALLER_DEPLOY_DIR_IMAGE}/${PXESERVER_LIVE_INSTALLER_FILE_NAME}-vmlinuz ${D}/var/installer/bootfiles/vmlinuz
    install -v -m 644 ${PXESERVER_LIVE_INSTALLER_DEPLOY_DIR_IMAGE}/${PXESERVER_LIVE_INSTALLER_FILE_NAME}-initrd.img ${D}/var/installer/bootfiles/initrd.img

    install -v -d ${D}/etc/nginx/sites-available/
    install -v -m 644 ${WORKDIR}/etc/nginx/sites-available/bootfiles.conf ${D}/etc/nginx/sites-available/

    install -v -d ${D}/var/installer/bootfiles
    install -v -m 644 ${WORKDIR}/default.ipxe ${D}/var/installer/bootfiles/
}