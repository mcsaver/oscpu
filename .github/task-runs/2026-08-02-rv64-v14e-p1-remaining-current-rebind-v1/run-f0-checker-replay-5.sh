#!/usr/bin/env bash

set -uo pipefail
exec bash "$(dirname "$0")/run-f0-checker-replay-common.sh" 5
