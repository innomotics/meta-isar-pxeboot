#
# Copyright (c) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT
#

inherit image

DESCRIPTION = "PXE Boot target demo image for PXE client (target devices)"

require ${@bb.utils.contains('ENABLE_ROOT_USER_INSTALLER_TARGET', '1', 'user-setup-root.inc', '', d)}

CUSTOMIZATIONS += "hostname"
