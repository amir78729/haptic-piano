#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
swift run --package-path "$ROOT" HapticPianoChecks
