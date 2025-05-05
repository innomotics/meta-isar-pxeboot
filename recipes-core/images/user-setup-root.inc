#
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT
#

USERS += "root"
USER_root[password] ??= "root"
USER_root[flags] += "clear-text-password"
