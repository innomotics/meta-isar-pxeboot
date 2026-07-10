#
# Copyright (c) Innomotics GmbH, 2026
#
# Authors:
#  Divya Shukla <divya.shukla.ext@innomotics.com>
#  Lukas Rabener <lukas.rabener@innomotics.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

DESCRIPTION = "PXE Server test suite"
MAINTAINER = "Lukas Rabener <lukas.rabener@innomotics.com>"

DEBIAN_DEPENDS += "dnsutils, curl"

FILESEXTRAPATHS:prepend := "${LAYERDIR_meta-isar-pxeboot}/:"

SRC_URI = " \
    git://github.com/bats-core/bats-core.git;protocol=https;destsuffix=bats-core-src;name=bats-core;branch=master \
    file://bats-format-lava \
    file://run_tests \
    file://run_tests_debug \
    file://run_tests_debug_all \
    file://run_tests_lava \
    file://tests/ \
    "

SRCREV_bats-core = "713504bc0224a19b3d7c7958c18dc07f64f54b44"

do_install[cleandirs] += "\
    ${D}/usr/bin \
    ${D}/usr/libexec/bats-core \
    ${D}/tests \
    "

do_install() {
    bash ${WORKDIR}/bats-core-src/install.sh ${D}/usr

    install -v -m 755 ${WORKDIR}/bats-format-lava ${D}/usr/libexec/bats-core/

    install -v -m 755 ${WORKDIR}/run_tests ${D}/usr/bin/
    install -v -m 755 ${WORKDIR}/run_tests_debug ${D}/usr/bin/
    install -v -m 755 ${WORKDIR}/run_tests_debug_all ${D}/usr/bin/
    install -v -m 755 ${WORKDIR}/run_tests_lava ${D}/usr/bin/

    cp -rf ${WORKDIR}/tests/* ${D}/tests/
}
