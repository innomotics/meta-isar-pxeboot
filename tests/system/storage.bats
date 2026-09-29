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

@test "/ filesystem is mounted" {
    run -0 findmnt -no SOURCE /
}

@test "/boot filesystem is mounted" {
    run -0 findmnt -no SOURCE /boot
}

@test "root filesystem type is ext4" {
    run -0 findmnt -no FSTYPE /
    [ "$output" = "ext4" ]
}

@test "boot filesystem type is vfat" {
    run -0 findmnt -no FSTYPE /boot
    [ "$output" = "vfat" ]
}

@test "root filesystem is mounted read write" {
    run -0 findmnt -no OPTIONS /
    [[ "$output" == *rw* ]]
}

@test "boot filesystem is mounted read write" {
    run -0 findmnt -no OPTIONS /boot
    [[ "$output" == *rw* ]]
}

@test "root filesystem usage below 90 percent" {
    run -0 bats_pipe df -P / \| awk 'NR==2 {gsub("%","",$5); exit !($5 < 90)}'
}

@test "boot filesystem usage below 90 percent" {
    run -0 bats_pipe df -P /boot \| awk 'NR==2 {gsub("%","",$5); exit !($5 < 90)}'
}
