#
# Copyright (c) Siemens AG, 2025
#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg

DESCRIPTION = "ipxe executable for efi based environments"
MAINTAINER = "Alexander Heinisch <alexander.heinisch@siemens.com>"

PXESERVER_IP ?= "192.168.148.42"

TEMPLATE_VARS = "\
    PXESERVER_IP \
    "

TEMPLATE_FILES = "\
    embedded-script.ipxe.tmpl \
    "

SRC_URI=" \
    git://github.com/ipxe/ipxe.git;protocol=https;destsuffix=ipxe-src;name=ipxe;branch=master \
    file://embedded-script.ipxe.tmpl \
    file://rules \
    file://0001-Patch-make-install.patch \
    file://0001-Fixing-iteration-on-autoexec.ipxe.patch \
    "

SRCREV_ipxe = "f7a1e9ef8e1dc22ebded786507b872a45e3fb05d"

PATCHTOOL = "git"
S = "${WORKDIR}/ipxe-src/src"


do_prepare_build() {
    deb_debianize

    install -v -m 644 ${WORKDIR}/embedded-script.ipxe ${S}/
}
