#!/usr/bin/env bash

readonly PXE_NS="pxe-client"
readonly PXE_SERVER_IF="veth-pxe-server"
readonly PXE_CLIENT_IF="veth-pxe-client"
readonly PXE_SERVER_TEST_IP="10.10.10.1"
readonly PXE_CLIENT_IP="10.10.10.2"
readonly PXE_NETMASK="24"
readonly PXE_MOUNT_POINT="/mnt/test-nfs"
readonly DEVICE_INFO_SUFFIX="/data"
readonly INSTALL_ROOTFS_SUFFIX="/rootfs"

get_export_path_by_suffix() {
    local suffix="$1"
    exportfs -v | awk -v suffix="$suffix" '$1 ~ (suffix "$") { print $1; exit }'
}

setup_pxe_client_namespace() {
    ip netns del "$PXE_NS" 2>/dev/null || true
    ip link del "$PXE_SERVER_IF" 2>/dev/null || true

    ip netns add "$PXE_NS"
    ip link add "$PXE_SERVER_IF" type veth peer name "$PXE_CLIENT_IF"
    ip link set "$PXE_CLIENT_IF" netns "$PXE_NS"
    ip addr add "$PXE_SERVER_TEST_IP/$PXE_NETMASK" dev "$PXE_SERVER_IF"
    ip link set "$PXE_SERVER_IF" up
    ip netns exec "$PXE_NS" ip addr add "$PXE_CLIENT_IP/$PXE_NETMASK" dev "$PXE_CLIENT_IF"
    ip netns exec "$PXE_NS" ip link set lo up
    ip netns exec "$PXE_NS" ip link set "$PXE_CLIENT_IF" up
}

cleanup_pxe_client_namespace() {
    ip netns del "$PXE_NS" 2>/dev/null || true
    ip link del "$PXE_SERVER_IF" 2>/dev/null || true
}

pxe_client_exec() {
    ip netns exec "$PXE_NS" "$@"
}

setup_nfs_export_context() {
    DEVICE_INFO_EXPORT="$(get_export_path_by_suffix "$DEVICE_INFO_SUFFIX")"
    INSTALL_ROOTFS_EXPORT="$(get_export_path_by_suffix "$INSTALL_ROOTFS_SUFFIX")"

    export DEVICE_INFO_EXPORT
    export INSTALL_ROOTFS_EXPORT
}

device_info_mount_and_touch() {
    pxe_client_exec sh -c "
      set -e
      mkdir -p '$PXE_MOUNT_POINT'
      umount -f '$PXE_MOUNT_POINT' 2>/dev/null || true
      timeout 10 mount -t nfs -o rw,soft,timeo=5,retrans=1 '${PXE_SERVER_TEST_IP}:${DEVICE_INFO_EXPORT}' '$PXE_MOUNT_POINT'
      touch '$PXE_MOUNT_POINT/device-info-rw-check'
    "
}

install_rootfs_mount_is_read_only() {
    pxe_client_exec sh -c "
      set -e
      mkdir -p '$PXE_MOUNT_POINT'
      umount -f '$PXE_MOUNT_POINT' 2>/dev/null || true
      timeout 10 mount -t nfs -o ro,soft,timeo=5,retrans=1 '${PXE_SERVER_TEST_IP}:${INSTALL_ROOTFS_EXPORT}' '$PXE_MOUNT_POINT'
      findmnt -no OPTIONS '$PXE_MOUNT_POINT' | grep -w ro
    "
}

install_rootfs_mount_and_touch() {
    pxe_client_exec sh -c "
      set -e
      mkdir -p '$PXE_MOUNT_POINT'
      umount -f '$PXE_MOUNT_POINT' 2>/dev/null || true
      timeout 10 mount -t nfs -o ro,soft,timeo=5,retrans=1 '${PXE_SERVER_TEST_IP}:${INSTALL_ROOTFS_EXPORT}' '$PXE_MOUNT_POINT'
      touch '$PXE_MOUNT_POINT/install-rootfs-ro-check'
    "
}

install_rootfs_mount_and_list() {
    pxe_client_exec sh -c "
      set -e
      mkdir -p '$PXE_MOUNT_POINT'
      umount -f '$PXE_MOUNT_POINT' 2>/dev/null || true
      timeout 10 mount -t nfs -o ro,soft,timeo=5,retrans=1 '${PXE_SERVER_TEST_IP}:${INSTALL_ROOTFS_EXPORT}' '$PXE_MOUNT_POINT'
      ls '$PXE_MOUNT_POINT'
    "
}
