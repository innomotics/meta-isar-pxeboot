#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

@test "hostname file exists" {
    [ -f /etc/hostname ]
}

@test "hostname is set" {
    run -0 hostname
    [ -n "$output" ]
}

@test "os-release ID exists" {
    run -0 grep '^ID=' /etc/os-release
}

@test "os-release NAME exists" {
    run -0 grep '^NAME=' /etc/os-release
}

@test "machine-id exists" {
    [ -s /etc/machine-id ]
}

@test "resolvconf directory exists" {
    [ -d /etc/resolvconf ]
}

@test "dnsmasq resolve conf hook script exists" {
    [ -f /etc/resolvconf/update.d/dnsmasq ]
}

@test "fstab exists" {
    [ -f /etc/fstab ]
}

@test "etc directory exists" {
    [ -d /etc ]
}

@test "dev directory exists" {
    [ -d /dev ]
}

@test "proc directory exists" {
    [ -d /proc ]
}

@test "sys directory exists" {
    [ -d /sys ]
}

@test "run directory exists" {
    [ -d /run ]
}

@test "journal can be read" {
    run -0 journalctl -n 1 --no-pager
}
