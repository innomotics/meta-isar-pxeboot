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

@test "dnsmasq service is running" {
    run -0 systemctl is-active --quiet dnsmasq.service
}

@test "dnsmasq service is enabled" {
    run -0 systemctl is-enabled --quiet dnsmasq.service
}

@test "dnsmasq process is listening on udp port 67 for dhcp" {
    run -0 ss -lunp 'sport = :67'
    [[ "$output" == *"dnsmasq"* ]]
}

@test "dnsmasq process is listening on udp port 69 for tftp" {
    run -0 ss -lunp 'sport = :69'
    [[ "$output" == *"dnsmasq"* ]]
}

@test "dnsmasq configuration file exists" {
    [ -f "$DNSMASQ_CONFIG_FILE" ]
}

@test "dnsmasq configuration file is not empty" {
    [ -s "$DNSMASQ_CONFIG_FILE" ]
}

@test "dnsmasq configuration syntax is valid" {
    run -0 dnsmasq --test -C "$DNSMASQ_CONFIG_FILE"
}

@test "dnsmasq dhcp-range directive exists with start and end addresses and lease time" {
    run -0 grep -Eq '^dhcp-range=[^,]+,[^,]+,[^,]+$' "$DNSMASQ_CONFIG_FILE"
}

@test "dnsmasq dhcp-boot directive exists with boot file value" {
    run -0 grep -Eq '^dhcp-boot=[^[:space:]]+$' "$DNSMASQ_CONFIG_FILE"
}

@test "dnsmasq disables default gateway assignment using dhcp-option 3" {
    run -0 grep -Fx 'dhcp-option=3' "$DNSMASQ_CONFIG_FILE"
}

@test "dnsmasq disables dns using dhcp-option 6" {
    run -0 grep -Fx 'dhcp-option=6' "$DNSMASQ_CONFIG_FILE"
}

@test "dnsmasq built-in tftp server is enabled" {
    run -0 grep -Fx 'enable-tftp' "$DNSMASQ_CONFIG_FILE"
}

@test "dnsmasq tftp-root directive exists with an absolute directory path" {
    run -0 grep -Eq '^tftp-root=/[^[:space:]]+$' "$DNSMASQ_CONFIG_FILE"
}

@test "dnsmasq configured tftp-root directory exists" {
    [ -d "$(sed -n 's/^tftp-root=//p' "$DNSMASQ_CONFIG_FILE")" ]
}

@test "pxe boot file defined in dhcp-boot exists in the configured tftp-root directory" {
    [ -f "$(sed -n 's/^tftp-root=//p' "$DNSMASQ_CONFIG_FILE")/$(sed -n 's/^dhcp-boot=//p' "$DNSMASQ_CONFIG_FILE")" ]
}
