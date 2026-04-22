#!/bin/bash
#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

arch="amd64"

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
	echo "  WORKDIR                        reuse an already existing workdir [path]"
	echo "  FIRMWARE_PATH                  firmware image to load [path]"
	echo "  FIRMWARE_VAR_PATH              firmware data image to load [path]"
	echo "  INSTALLER_TARGET_DISK_TYPE     disk type the installer expects [ide-hd, nvme] (default: ide-hd)"
	echo "  TARGET_DISK_SIZE               size of the (target) disk used in the vm (default: 15G)"
	echo "  TAP_IFNAME_PXE_TARGET          name of the tap interface to use (default: tap-pxe-target)"
	echo "  DISPLAY                        enables UI for qemu if not empty"
	echo "  CLEANUP                        remove workdir [boolean] (default: false)"
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

OVMF_PATH="/usr/share/OVMF/"
FIRMWARE_PATH=${FIRMWARE_PATH:-"${OVMF_PATH}/OVMF_CODE_4M.fd"}
FIRMWARE_VAR_PATH=${FIRMWARE_VAR_PATH:-"${OVMF_PATH}/OVMF_VARS_4M.fd"}

GUEST_FIRMWARE=${WORKDIR}/fw.image
GUEST_FIRMWARE_VARS=${WORKDIR}/fw.image.vars

## Prepare stuff
cp ${FIRMWARE_PATH} ${GUEST_FIRMWARE}
cp ${FIRMWARE_VAR_PATH} ${GUEST_FIRMWARE_VARS}


# checks before we even start (all utils installed, ports available, ...)
echo "Precheck..."

program_installed qemu-system-x86_64 qemu-system-x86

echo "Precheck successful"

####################
# Start of guest vm
####################

echo "Setup VM in workdir ${WORKDIR}"

# start qemu based system under test
QEMU_BOARD=" \
    -cpu qemu64 \
    -smp 4 \
    -machine q35,accel=kvm:tcg \
    -global ICH9-LPC.noreboot=off \
    -m 16G \
	"

TARGET_DISK_SIZE=${TARGET_DISK_SIZE:-"15G"}
TARGET_DISK="${WORKDIR}/target-disk.img"
qemu-img create -f qcow2 ${TARGET_DISK} ${TARGET_DISK_SIZE}


INSTALLER_TARGET_DISK_TYPE=${INSTALLER_TARGET_DISK_TYPE:-"ide-hd"}

QEMU_DISK=" -device ${INSTALLER_TARGET_DISK_TYPE},serial=deadbeef,drive=storage \
    -drive if=pflash,format=raw,unit=0,readonly=on,file=${GUEST_FIRMWARE} \
    -drive if=pflash,format=raw,file=${GUEST_FIRMWARE_VARS} \
    -drive file=${TARGET_DISK},if=none,format=qcow2,id=storage \
    "

# Create network interfaces bound to pci: enp1s0, enp2s0 and enp3s0
TAP_IFNAME_PXE_TARGET=${TAP_IFNAME_PXE_TARGET:-"tap-pxe-target"}

#IPXE_ROM_FILE="../ipxe-upstream/src/bin-x86_64-efi/ipxe.efirom"
IPXE_ROM_FILE="" # do not use Debian qemu-ipxe prebundled rom file, as it ships with an outdated buggy version

QEMU_NETWORK=" \
    -netdev tap,id=cloud,ifname=${TAP_IFNAME_PXE_TARGET},script=no,downscript=no \
    \
    -device pcie-root-port,id=pcie_port1,bus=pcie.0,chassis=1 \
    \
    -device virtio-net-pci,netdev=cloud,bus=pcie_port1 \
    \
	-device virtio-rng-pci \
    -global virtio-net-pci.romfile=${IPXE_ROM_FILE} \
    "

GUEST_SWTPM_DIR=${WORKDIR}/swtpm
GUEST_SWTPM_SOCK=${WORKDIR}/swtpm.sock
mkdir -p "${GUEST_SWTPM_DIR}"
if swtpm socket -d --tpmstate dir="${GUEST_SWTPM_DIR}" \
		 --ctrl type=unixio,path=${GUEST_SWTPM_SOCK} \
		 --tpm2; then
	TPM_DEVICE=tpm-tis-device
	case "${arch}" in
		x86|x86_64|amd64)
			TPM_DEVICE=tpm-tis
			;;
	esac

    QEMU_TPM_SETUP=" \
		-chardev socket,id=chrtpm,path=${GUEST_SWTPM_SOCK} \
		-tpmdev emulator,id=tpm0,chardev=chrtpm \
		-device ${TPM_DEVICE},tpmdev=tpm0 \
		"
fi

QEMU_SMBIOS="\
    -smbios type=1,serial=DEAD-BEEF-ACAB-DEAD-BEEF \
    "

QEMU_MISC="-serial mon:stdio"

if [ -z "${DISPLAY}" ]; then
    QEMU_MISC="${QEMU_MISC} -nographic"
fi

echo "Starting VM..."
qemu-system-x86_64 ${QEMU_BOARD} ${QEMU_DISK} ${QEMU_NETWORK} ${QEMU_TPM_SETUP} ${QEMU_SMBIOS} ${QEMU_MISC}

###########
## Cleanup
###########
if ${CLEANUP}; then
    echo "Cleanup"
    rm -rf ${WORKDIR}
fi
