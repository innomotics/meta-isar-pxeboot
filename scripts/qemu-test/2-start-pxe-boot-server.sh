#!/bin/bash
#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

SCRIPT_DIR=$( dirname -- "$( readlink -f -- "$0"; )"; )
. ${SCRIPT_DIR}/env.sh
. ${SCRIPT_DIR}/lib.sh

#######
# Help
#######
usage()
{
	echo "Usage: $0"
	echo
	echo "The architecture for the qemu system is ${arch}"
	echo
	echo "Environment variables:"
    echo "  WORKDIR                reuse an already existing workdir [path]"
	echo "  PXE_SERVER_IMAGE_PATH  disk image of pxe boot server to load [path]"
    echo "  DISPLAY                enables UI for qemu if not empty"
	echo "  CLEANUP                remove workdir [boolean] (default: false)"
	exit 1
}

######
# CLI
######
if [ $# -gt 0 ]; then
	case "$1" in
	-h | --help)
		usage
		;;
	*)
		echo "unknown argument $@"
		usage
		;;
	esac
fi

fresh_run=true
if [ ! -z $WORKDIR ]; then
    echo "Rerun existing setup"

    if [ ! -d $WORKDIR ]; then
        echo "Specified WORKDIR=${WORKDIR} is no valid directory. -> Abort."
        exit 1
    fi

    echo "Reuse setup from $WORKDIR"
    fresh_run=false
else
    WORKDIR=$(mktemp -d -p ${PWD} workdir-XXXXX)
fi

PXE_SERVER_IMAGE_PATH=${PXE_SERVER_IMAGE_PATH:-build/tmp-pxe-boot-server-qemuamd64/deploy/images/qemuamd64-qemuamd64/pxe-boot-server-debian-bookworm-qemuamd64-qemuamd64.wic}

OVMF_PATH="/usr/share/OVMF/"
FIRMWARE_PATH=${FIRMWARE_PATH:-"${OVMF_PATH}/OVMF_CODE_4M.fd"}
FIRMWARE_VAR_PATH=${FIRMWARE_VAR_PATH:-"${OVMF_PATH}/OVMF_VARS_4M.fd"}

CLEANUP=${CLEANUP:-false}

GUEST_IMAGE=${WORKDIR}/os.image
GUEST_FIRMWARE=${WORKDIR}/fw.image
GUEST_FIRMWARE_VARS=${WORKDIR}/fw.image.vars

if $fresh_run; then
    ## Prepare stuff
    cp ${PXE_SERVER_IMAGE_PATH} ${GUEST_IMAGE}
    cp ${FIRMWARE_PATH} ${GUEST_FIRMWARE}
    cp ${FIRMWARE_VAR_PATH} ${GUEST_FIRMWARE_VARS}
fi

###########
# Precheck
###########

# checks before we even start (all utils installed, ports available, ...)
echo "Precheck..."

program_installed qemu-system-x86_64 qemu-system-x86

echo "Precheck successful"


#########################
# Start of pxe-server vm
#########################

echo "Setup PXE Server VM in workdir ${WORKDIR}"

# start qemu based system under test
QEMU_BOARD=" \
    -cpu qemu64 \
    -smp 4 \
    -machine q35,accel=kvm:tcg \
    -global ICH9-LPC.noreboot=off \
    -m 16G \
    "

QEMU_DISK="\
    -device ide-hd,serial=deadbeef,drive=disk \
    -drive if=pflash,format=raw,unit=0,readonly=on,file=${GUEST_FIRMWARE} \
    -drive if=pflash,format=raw,file=${GUEST_FIRMWARE_VARS} \
    -drive file=${GUEST_IMAGE},discard=unmap,if=none,id=disk,format=raw \
    "

# Create network interfaces bound to pci: enp1s0, enp2s0 and enp3s0
TAP_IFNAME_PXE_SERVER=${TAP_IFNAME_PXE_SERVER:-"tap-pxe-server"}
QEMU_NETWORK=" \
    -netdev tap,id=pxe-net0,ifname=${TAP_IFNAME_PXE_SERVER},script=no,downscript=no \
    -device e1000,netdev=pxe-net0,mac=52:55:00:d1:55:01 \
    "

QEMU_MISC="-serial mon:stdio"

if [ -z "${DISPLAY}" ]; then
    QEMU_MISC="${QEMU_MISC} -nographic"
fi

echo "Starting VM..."
qemu-system-x86_64 ${QEMU_BOARD} ${QEMU_DISK} ${QEMU_NETWORK} ${QEMU_MISC}


###########
## Cleanup
###########
if ${CLEANUP}; then
    echo "Cleanup"
    rm -rf ${WORKDIR}
fi
