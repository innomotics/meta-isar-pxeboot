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

readonly DNSMASQ_CONFIG_FILE="/etc/dnsmasq.conf"

setup_file() {
    run -0 bats_pipe sed -n 's/^tftp-root=//p' "$DNSMASQ_CONFIG_FILE" \| head -n1
    export TFTP_ROOT="$output"

    run -0 bats_pipe sed -n 's/^dhcp-boot=\([^,]*\).*$/\1/p' "$DNSMASQ_CONFIG_FILE" \| head -n1
    export PXE_BOOT_FILE="$output"

    TEST_TMPDIR="$(mktemp -d)"
    export TEST_TMPDIR
}

teardown_file() {
    rm -rf "$TEST_TMPDIR"
}

@test "pxe boot file exists in configured tftp-root directory" {
    [ -f "$TFTP_ROOT/$PXE_BOOT_FILE" ]
}

@test "pxe boot file in configured tftp-root directory is not empty" {
    [ -s "$TFTP_ROOT/$PXE_BOOT_FILE" ]
}

@test "pxe boot file downloaded via tftp exists in temporary directory" {
    run -0 curl --max-time 2 -fsS -o "$TEST_TMPDIR/pxe_tftp_test_dl" "tftp://127.0.0.1/$PXE_BOOT_FILE"
    [ -f "$TEST_TMPDIR/pxe_tftp_test_dl" ]
}

@test "pxe boot file downloaded via tftp matches file in configured tftp-root directory" {
    run -0 curl --max-time 2 -fsS -o "$TEST_TMPDIR/pxe_tftp_test_compare" "tftp://127.0.0.1/$PXE_BOOT_FILE"
    run -0 cmp "$TEST_TMPDIR/pxe_tftp_test_compare" "$TFTP_ROOT/$PXE_BOOT_FILE"
}
