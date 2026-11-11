#!/usr/bin/env bash
# Install the Gmail secret helper. Does not create or edit an account.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "${HOME}/.local/bin"
install -m 755 "${root}/himalaya-gmail-secret" "${HOME}/.local/bin/himalaya-gmail-secret"
echo "Installed ${HOME}/.local/bin/himalaya-gmail-secret"
