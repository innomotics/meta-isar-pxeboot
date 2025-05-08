#! /bin/bash
#
# Authors:
#  Alexander Heinisch <alexander.heinisch@siemens.com>
#
# SPDX-License-Identifier: MIT
#

program_installed() {
    if ! command -v $1 &> /dev/null
    then
        echo "$1 could not be found"
        if [ ! -z $2 ]; then
            echo "On debian based sytems you may install it with: \"apt install $2\""
        fi
        exit 1
    fi
}
