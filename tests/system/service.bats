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

@test "system is running" {
    run -0 systemctl is-system-running --quiet
}

@test "systemd-modules-load service is active" {
    run -0 systemctl is-active --quiet systemd-modules-load.service
}

@test "systemd-modules-load service is enabled" {
    run -0 systemctl is-enabled --quiet systemd-modules-load.service
}

@test "systemd-journald service is active" {
    run -0 systemctl is-active --quiet systemd-journald.service
}

@test "systemd-journald service is enabled" {
    run -0 systemctl is-enabled --quiet systemd-journald.service
}

@test "systemd-networkd service is active" {
    run -0 systemctl is-active --quiet systemd-networkd.service
}

@test "systemd-networkd service is enabled" {
    run -0 systemctl is-enabled --quiet systemd-networkd.service
}

@test "systemd-networkd-wait-online service is active" {
    run -0 systemctl is-active --quiet systemd-networkd-wait-online.service
}

@test "systemd-networkd-wait-online service is enabled" {
    run -0 systemctl is-enabled --quiet systemd-networkd-wait-online.service
}
