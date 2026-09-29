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

setup_file() {
    run -0 bats_pipe ip -o link show \| awk -F': ' '$2 != "lo" { print $2; exit }' \| cut -d'@' -f1
    export PRIMARY_INTERFACE="$output"
}

@test "primary interface exists" {
    run -0 test -n "$PRIMARY_INTERFACE"
}

@test "loopback interface exists" {
    run -0 ip link show lo
}

@test "loopback interface is up" {
    run -0 bats_pipe ip link show lo \| grep '<.*UP.*>'
}

@test "loopback interface has ipv4" {
    run -0 bats_pipe ip -4 addr show lo \| grep '127.0.0.1/'
}

@test "primary interface is present in sysfs" {
    run -0 test -e "/sys/class/net/$PRIMARY_INTERFACE"
}

@test "primary interface is up" {
    run -0 bats_pipe ip link show "$PRIMARY_INTERFACE" \| grep '<.*UP.*>'
}

@test "primary interface has a route" {
    run -0 bats_pipe ip route \| grep "dev $PRIMARY_INTERFACE"
}
