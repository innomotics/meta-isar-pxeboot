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

readonly NGINX_SERVICE="nginx.service"
readonly PID_FILE="/run/nginx.pid"
readonly PXE_BOOTFILES_DIR="/var/installer/bootfiles"
readonly PXE_HTTP_BASE_URL="http://127.0.0.1/bootfiles"
readonly CURL_TIMEOUT_SECONDS="1"

@test "nginx service is running" {
    run -0 systemctl is-active --quiet "$NGINX_SERVICE"
}

@test "nginx service is enabled" {
    run -0 systemctl is-enabled --quiet "$NGINX_SERVICE"
}

@test "nginx configuration test is successful" {
    run -0 nginx -t
}

@test "nginx is running and listening on port 80 http" {
    run -0 ss -ltnp 'sport = :80'
    [[ "$output" == *"nginx"* ]]
}

@test "nginx PID file exists" {
    [ -f "$PID_FILE" ]
}

@test "nginx PID file is not empty" {
    [ -s "$PID_FILE" ]
}

@test "nginx PID in the PID file is not zero" {
    run -0 test "$(<"$PID_FILE")" -ne 0
}

@test "pxe bootfiles directory exists" {
    [ -d "$PXE_BOOTFILES_DIR" ]
}

@test "default.ipxe file exists" {
    [ -f "$PXE_BOOTFILES_DIR/default.ipxe" ]
}

@test "default.ipxe file is not empty" {
    [ -s "$PXE_BOOTFILES_DIR/default.ipxe" ]
}

@test "initrd.img file exists" {
    [ -f "$PXE_BOOTFILES_DIR/initrd.img" ]
}

@test "initrd.img file is not empty" {
    [ -s "$PXE_BOOTFILES_DIR/initrd.img" ]
}

@test "vmlinuz file exists" {
    [ -f "$PXE_BOOTFILES_DIR/vmlinuz" ]
}

@test "vmlinuz file is not empty" {
    [ -s "$PXE_BOOTFILES_DIR/vmlinuz" ]
}

@test "http request for default.ipxe returns status code 200" {
    run -0 curl --max-time "$CURL_TIMEOUT_SECONDS" -sS -o /dev/null -w "%{http_code}" \
        "$PXE_HTTP_BASE_URL/default.ipxe"
    [ "$output" = "200" ]
}

@test "http request for initrd.img returns status code 200" {
    run -0 curl --max-time "$CURL_TIMEOUT_SECONDS" -sS -o /dev/null -w "%{http_code}" \
        "$PXE_HTTP_BASE_URL/initrd.img"
    [ "$output" = "200" ]
}

@test "http request for vmlinuz returns status code 200" {
    run -0 curl --max-time "$CURL_TIMEOUT_SECONDS" -sS -o /dev/null -w "%{http_code}" \
        "$PXE_HTTP_BASE_URL/vmlinuz"
    [ "$output" = "200" ]
}

@test "http content for default.ipxe matches local file content" {
    run -0 bats_pipe curl --max-time "$CURL_TIMEOUT_SECONDS" -fsS "$PXE_HTTP_BASE_URL/default.ipxe" \| \
        cmp -s - "$PXE_BOOTFILES_DIR/default.ipxe"
}

@test "http content for initrd.img matches local file content" {
    run -0 bats_pipe curl --max-time "$CURL_TIMEOUT_SECONDS" -fsS "$PXE_HTTP_BASE_URL/initrd.img" \| \
        cmp -s - "$PXE_BOOTFILES_DIR/initrd.img"
}

@test "http content for vmlinuz matches local file content" {
    run -0 bats_pipe curl --max-time "$CURL_TIMEOUT_SECONDS" -fsS "$PXE_HTTP_BASE_URL/vmlinuz" \| \
        cmp -s - "$PXE_BOOTFILES_DIR/vmlinuz"
}

@test "http request for missing pxe file returns status code 404" {
    run -0 curl --max-time "$CURL_TIMEOUT_SECONDS" -sS -o /dev/null -w "%{http_code}" \
        "$PXE_HTTP_BASE_URL/does-not-exist"
    [ "$output" = "404" ]
}
