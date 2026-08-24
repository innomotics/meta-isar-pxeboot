#
# Copyright (c) Innomotics GmbH, 2026
#
# Authors:
#  Lukas Rabener <lukas.rabener@innomotics.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-customization

DESCRIPTION = "Apply sysctl kernel settings"
MAINTAINER = "Lukas Rabener <lukas.rabener@innomotics.com>"

SYSCTL_KERNEL_PRINTK ?= "3 4 1 3"

TEMPLATE_VARS = " \
    SYSCTL_KERNEL_PRINTK \
    "

TEMPLATE_FILES = " \
    99-silent-printk.conf.tmpl \
    "

SRC_URI = " \
    file://99-silent-printk.conf.tmpl \
    "

do_install[cleandirs] += " \
    ${D}/etc/sysctl.d \
    "

do_install() {
    install -v -m 644 ${WORKDIR}/99-silent-printk.conf ${D}/etc/sysctl.d/
}
