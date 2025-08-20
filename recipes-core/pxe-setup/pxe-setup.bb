#
# Copyright (c) Siemens AG, 2025
#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

DESCRIPTION = "PXE Server setup to boot devices via pxe boot."
MAINTAINER = "Alexander Heinisch <alexander.heinisch@siemens.com>"

DEPENDS = " ipxe-efi ipxe-bootfiles-http-server"
DEPENDS:remove:pxe-syslinux = " ipxe-efi ipxe-bootfiles-http-server"

DEBIAN_DEPENDS = "dnsmasq, ipxe-efi, ipxe-bootfiles-http-server"
DEBIAN_DEPENDS:remove:pxe-syslinux = "ipxe-efi, ipxe-bootfiles-http-server"

PXESERVER_INTERFACE_NAMES ?= "e*"
PXESERVER_IP ?= "192.168.148.42"
PXESERVER_NETMASK ?= "24"
PXESERVER_DHCP_RANGE_START ?= "192.168.148.200"
PXESERVER_DHCP_RANGE_END ?= "192.168.148.250"
PXESERVER_DHCP_TFTP_ROOT ?= "/var/installer/tftp"
PXESERVER_DHCP_BOOT_FILE ?= "uefi/ipxe.efi"
PXESERVER_DHCP_BOOT_FILE:pxe-syslinux ?= "uefi/syslinux.efi"

PXESERVER_LIVE_INSTALLER_ADDITIONAL_KERNEL_CMDLINE ?= ""

TEMPLATE_VARS = "\
    PXESERVER_INTERFACE_NAMES \
    PXESERVER_IP \
    PXESERVER_NETMASK \
    PXESERVER_DHCP_RANGE_START \
    PXESERVER_DHCP_RANGE_END \
    PXESERVER_DHCP_TFTP_ROOT \
    PXESERVER_DHCP_BOOT_FILE \
    PXESERVER_LIVE_INSTALLER_ADDITIONAL_KERNEL_CMDLINE \
    "

TEMPLATE_FILES = "\
    etc/dnsmasq.conf.tmpl \
    etc/systemd/network/10-main.network.tmpl \
    "

TEMPLATE_FILES:append:ipxe-autoexec = "\
    ipxe/autoexec.ipxe.tmpl \
    "

SRC_URI = "\
    file://preinst \
    file://postinst \
    file://etc/ \
    "
SRC_URI:append:ipxe-autoexec = "\
    file://ipxe/autoexec.ipxe.tmpl \
    "

# using syslinux
TEMPLATE_FILES:append:pxe-syslinux = "\
    pxelinux.cfg/default.tmpl \
    "
SRC_URI:append:pxe-syslinux="\
    file://pxelinux.cfg/ \
    https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz;name=syslinux \
    "

SRC_URI[syslinux.sha256sum] = "26d3986d2bea109d5dc0e4f8c4822a459276cf021125e8c9f23c3cca5d8c850e"

do_install() {
    install -v -d ${D}/etc
    install -v -m 644 ${WORKDIR}/etc/dnsmasq.conf ${D}/etc/

    install -v -d ${D}/etc/systemd/network
    install -v -m 644 ${WORKDIR}/etc/systemd/network/10-main.network ${D}/etc/systemd/network/

    install -v -d ${D}/etc/systemd/system/systemd-networkd-wait-online.service.d
    install -v -m 644 ${WORKDIR}/etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf ${D}/etc/systemd/system/systemd-networkd-wait-online.service.d/

    install -v -d ${D}/${PXESERVER_DHCP_TFTP_ROOT}/uefi
}

do_install:append:ipxe-autoexec() {
    install -v -m 644 ${WORKDIR}/ipxe/autoexec.ipxe ${D}/${PXESERVER_DHCP_TFTP_ROOT}/
}


PXESERVER_MC ??= "pxe-boot-server"
PXESERVER_LIVE_INSTALLER_MC ??= "isar-installer"
PXESERVER_LIVE_INSTALLER_DISTRO ??= "${DISTRO}"
PXESERVER_LIVE_INSTALLER_MACHINE ??= "${MACHINE}"
PXESERVER_LIVE_INSTALLER_IMAGE ??= "isar-image-installer"

PXESERVER_LIVE_INSTALLER_TMPDIR ??= "${TOPDIR}/tmp"
PXESERVER_LIVE_INSTALLER_DEPLOY_DIR ??= "${PXESERVER_LIVE_INSTALLER_TMPDIR}/deploy"
PXESERVER_LIVE_INSTALLER_DEPLOY_DIR_IMAGE ??= "${PXESERVER_LIVE_INSTALLER_DEPLOY_DIR}/images/${PXESERVER_LIVE_INSTALLER_MACHINE}"
PXESERVER_LIVE_INSTALLER_FILE_NAME ??= "${PXESERVER_LIVE_INSTALLER_IMAGE}-${PXESERVER_LIVE_INSTALLER_DISTRO}-${PXESERVER_LIVE_INSTALLER_MACHINE}"

PXESERVER_LIVE_INSTALLER_DESTINATION_BOOTSTRAPPER ??= "${PXESERVER_DHCP_TFTP_ROOT}/uefi/live-system-bootstrapper/"

INSTALLER_IMAGE_DEPENDS ??= "mc:${PXESERVER_MC}:${PXESERVER_LIVE_INSTALLER_MC}:${PXESERVER_LIVE_INSTALLER_IMAGE}:do_copy_boot_files"

do_install[mcdepends] = "${INSTALLER_IMAGE_DEPENDS}"


do_install:append:pxe-syslinux() {

    install -v -m 644 ${WORKDIR}/syslinux-6.03/efi64/efi/syslinux.efi ${D}/${PXESERVER_DHCP_TFTP_ROOT}/uefi/
    install -v -m 644 ${WORKDIR}/syslinux-6.03/efi64/com32/elflink/ldlinux/ldlinux.e64 ${D}/${PXESERVER_DHCP_TFTP_ROOT}/uefi/
    install -v -m 644 ${WORKDIR}/syslinux-6.03/efi64/com32/libutil/libutil.c32 ${D}/${PXESERVER_DHCP_TFTP_ROOT}/uefi/
    install -v -m 644 ${WORKDIR}/syslinux-6.03/efi64/com32/menu/menu.c32 ${D}/${PXESERVER_DHCP_TFTP_ROOT}/uefi/
    # install -v -m 644 ${WORKDIR}/syslinux-6.03/efi64/com32/menu/vesamenu.c32 ${D}/${PXESERVER_DHCP_TFTP_ROOT}/uefi/

    install -v -d ${D}/${PXESERVER_DHCP_TFTP_ROOT}/uefi/pxelinux.cfg/
    install -v -m 644 ${WORKDIR}/pxelinux.cfg/default ${D}/${PXESERVER_DHCP_TFTP_ROOT}/uefi/pxelinux.cfg/

    # Copy kernel and initrd to boot
    install -v -d ${D}/${PXESERVER_LIVE_INSTALLER_DESTINATION_BOOTSTRAPPER}
    install -v -m 644 ${PXESERVER_LIVE_INSTALLER_DEPLOY_DIR_IMAGE}/${PXESERVER_LIVE_INSTALLER_FILE_NAME}-vmlinuz ${D}/${PXESERVER_LIVE_INSTALLER_DESTINATION_BOOTSTRAPPER}/vmlinuz
    install -v -m 644 ${PXESERVER_LIVE_INSTALLER_DEPLOY_DIR_IMAGE}/${PXESERVER_LIVE_INSTALLER_FILE_NAME}-initrd.img ${D}/${PXESERVER_LIVE_INSTALLER_DESTINATION_BOOTSTRAPPER}/initrd.img
}
