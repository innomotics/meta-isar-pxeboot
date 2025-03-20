#! /bin/bash
#
# Copyright (c) Siemens AG, 2025
#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

if [ -f /etc/meta-pxe-boot.env ]; then
    echo "Found global /etc/meta-pxe-boot.env -> apply"
    source /etc/meta-pxe-boot.env
fi

if [ -f .env ]; then
    echo "Found local .env -> apply"
    source .env
fi

BUILD_SPEC=${1:-"kas-pxe-boot.yml"}
BUILD_CMD=${BUILD_CMD:-"build"}

echo "Building \"${BUILD_SPEC}\" ..."

KAS_IMAGE_VERSION="4.7" ./kas-container     \
                ${BUILD_CMD} ${BUILD_SPEC}
