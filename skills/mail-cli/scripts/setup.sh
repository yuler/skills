#!/usr/bin/env bash
# Install the Gmail secret helper and, when no account exists, write
# ~/.config/himalaya/config.toml from the Gmail template. Only the address
# changes. An existing account is left in place.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/himalaya"
config="${config_dir}/config.toml"
secret="${config_dir}/gmail-app-password"
template="${root}/gmail.config.toml"

mkdir -p "${HOME}/.local/bin"
install -m 755 "${root}/himalaya-gmail-secret" "${HOME}/.local/bin/himalaya-gmail-secret"

if [[ -f "${config}" ]] && grep -q '^\[accounts\.' "${config}"; then
  echo "Himalaya already has an account. Left ${config} in place."
  exit 0
fi

email="${1:-}"
if [[ -z "${email}" ]]; then
  read -r -p "Gmail address: " email
fi
if [[ ! "${email}" =~ ^[A-Za-z0-9._%+-]+@gmail\.com$ ]]; then
  echo "Need a Gmail address, such as name@gmail.com." >&2
  exit 2
fi

name="${email%@*}"
mkdir -p "${config_dir}"
sed -e "s/__EMAIL__/${email}/g" -e "s/__NAME__/${name}/g" "${template}" > "${config}"
chmod 600 "${config}"

echo "Wrote ${config}"
if [[ ! -s "${secret}" ]]; then
  echo "Write the Google app password to:"
  echo "  ${secret}"
  echo "Create one at https://myaccount.google.com/apppasswords"
fi
