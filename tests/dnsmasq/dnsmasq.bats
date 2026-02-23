#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

@test "dnsmasq service is running" {
   run -0 systemctl is-active --quiet dnsmasq.service
}

@test "dnsmasq service is enabled" {
   run -0 systemctl is-enabled --quiet dnsmasq.service
}
