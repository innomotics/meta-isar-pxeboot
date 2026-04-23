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

EMBEDDED_SCRIPT_ARGS = ""
EMBEDDED_SCRIPT_ARGS:append:ipxe-embedded = "EMBED=embedded-script.ipxe"
# EMBEDDED_SCRIPT_ARGS:ipxe-embedded += " DEBUG=init,efi_autoexec,efi_local,efi_file,efi_block,efi_driver,efi_pci,efi_utils,mnpnet,mnp"

TEMPLATE_VARS = "\
    EMBEDDED_SCRIPT_ARGS \
    "

TEMPLATE_VARS:append:ipxe-embedded = "\
    PXESERVER_IP \
    "

TEMPLATE_FILES = "\
    rules.tmpl \
    "

TEMPLATE_FILES:append:ipxe-embedded = "\
    embedded-script.ipxe.tmpl \
    "

SRC_URI=" \
    git://github.com/ipxe/ipxe.git;protocol=https;destsuffix=ipxe-src;name=ipxe;branch=master \
    file://0001-Patch-make-install.patch \
    file://rules.tmpl \
    "
SRC_URI:append:ipxe-embedded = "\
    file://embedded-script.ipxe.tmpl \
    "

SRCREV_ipxe = "1c54e7e8a454f80a77350b52d21ec5ce55ca667b"

PATCHTOOL = "git"
S = "${WORKDIR}/ipxe-src/src"


do_prepare_build() {
    deb_debianize
}

do_prepare_build:append:ipxe-embedded() {
    install -v -m 644 ${WORKDIR}/embedded-script.ipxe ${S}/
}
