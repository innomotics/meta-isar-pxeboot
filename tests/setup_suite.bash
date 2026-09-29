#
# Copyright (c) Innomotics GmbH, 2026
#
# Authors:
#  Divya Shukla <divya.shukla.ext@innomotics.com>
#
# SPDX-License-Identifier: MIT
#

if [ -z "${BATS_TEST_RETRIES}" ]; then
  export BATS_TEST_RETRIES=3
fi

setup_suite() {
  echo "Setup testsuite"
}

teardown_suite() {
  echo "Teardown testsuite"
}
