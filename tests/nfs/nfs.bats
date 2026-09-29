#!/usr/bin/env bats
#
# Copyright (c) Innomotics GmbH, 2026
#
# Authors:
#  Divya Shukla <divya.shukla.ext@innomotics.com>
#
# SPDX-License-Identifier: MIT
#

bats_require_minimum_version 1.5.0

load ../helper/nfs.sh

setup() {
    dmesg -n 1
    setup_pxe_client_namespace
    setup_nfs_export_context
}

teardown() {
    pxe_client_exec umount -f "$PXE_MOUNT_POINT" 2>/dev/null || true
    cleanup_pxe_client_namespace
}

@test "nfs-server service is active" {
    run -0 systemctl is-active --quiet nfs-server.service
}

@test "nfs-server service is enabled" {
    run -0 systemctl is-enabled --quiet nfs-server.service
}

@test "rpcbind service is active" {
    run -0 systemctl is-active --quiet rpcbind.service
}

@test "rpcbind service is enabled" {
    run -0 systemctl is-enabled --quiet rpcbind.service
}

@test "nfs server port 2049 is listening on host" {
    run -0 bats_pipe ss -tln \| grep -E ':2049 '
}

@test "device-info export path is discovered from exportfs output" {
    [ -n "$DEVICE_INFO_EXPORT" ]
}

@test "install-rootfs export path is discovered from exportfs output" {
    [ -n "$INSTALL_ROOTFS_EXPORT" ]
}

@test "device-info export directory exists on filesystem" {
    [ -d "$DEVICE_INFO_EXPORT" ]
}

@test "install-rootfs export directory exists on filesystem" {
    [ -d "$INSTALL_ROOTFS_EXPORT" ]
}

@test "device-info export path exists in exportfs output" {
    run -0 bats_pipe exportfs -v \| grep -F -- "$DEVICE_INFO_EXPORT"
}

@test "install-rootfs export path exists in exportfs output" {
    run -0 bats_pipe exportfs -v \| grep -F -- "$INSTALL_ROOTFS_EXPORT"
}

@test "device-info export allows file creation from pxe client namespace" {
    run -0 device_info_mount_and_touch
}

@test "install-rootfs export is read only in mount options from pxe client namespace" {
    run -0 install_rootfs_mount_is_read_only
}

@test "install-rootfs export rejects file creation from pxe client namespace" {
    run ! install_rootfs_mount_and_touch
}

@test "install-rootfs export allows directory listing from pxe client namespace" {
    run -0 install_rootfs_mount_and_list
}
