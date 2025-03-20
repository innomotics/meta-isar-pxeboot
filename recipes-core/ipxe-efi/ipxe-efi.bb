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
    "

SRCREV_ipxe = "bdb5b4aef46ed34b47094652f3eefc7d0463d166"

PATCHTOOL = "git"
S = "${WORKDIR}/ipxe-src/src"


do_prepare_build() {
    deb_debianize

    install -v -m 644 ${WORKDIR}/embedded-script.ipxe ${S}/
}
