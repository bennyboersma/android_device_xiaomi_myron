#!/bin/bash
#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -euo pipefail

MY_DIR="${BASH_SOURCE[0]%/*}"
if [[ ! -d "${MY_DIR}" ]]; then
    MY_DIR="${PWD}"
fi

PY_SETUP_SCRIPT="${MY_DIR}/setup-makefiles.py"
if [ ! -f "${PY_SETUP_SCRIPT}" ]; then
    echo "Unable to find ${PY_SETUP_SCRIPT}"
    exit 1
fi

exec "${PY_SETUP_SCRIPT}" "$@"
