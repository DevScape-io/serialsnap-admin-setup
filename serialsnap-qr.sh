#!/usr/bin/env bash
# SerialSnap setup code — terminal edition.
#
# Turns an Apple School Manager or Apple Business API account into a QR code that
# technicians scan in SerialSnap under Add organization › Scan setup QR code.
# It's the same payload as serialsnap-setup.html.
#
# Nothing is written to disk, passed as a command-line argument or sent over the
# network. The QR is drawn in this terminal and the screen and scrollback are wiped
# when you press Return, after two minutes, or on Ctrl-C.
#
# Usage:
#   ./serialsnap-qr.sh               Client ID, Key ID and private key (one scan sets up the device)
#   ./serialsnap-qr.sh --key-only    Private key only, for when your MDM pushes the Client ID and Key ID
#   ./serialsnap-qr.sh --no-key      Client ID and Key ID only; the technician imports the .pem separately
#
# Requires: qrencode (brew install qrencode) and openssl (included with macOS).
# Source: https://github.com/DevScape-io/serialsnap-admin-setup

set -euo pipefail

mode=full
case "${1:-}" in
  "") ;;
  --key-only) mode=key ;;
  --no-key) mode=details ;;
  -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "Unknown option: $1 (try --help)" >&2; exit 64 ;;
esac

die() { echo "✗ $*" >&2; exit 1; }

command -v qrencode >/dev/null || die "qrencode isn't installed. Install it with: brew install qrencode"
command -v openssl >/dev/null || die "openssl isn't installed."

wipe() { printf '\033[2J\033[3J\033[H'; }

# Escapes a single-line value for a JSON string.
json_string() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  printf '"%s"' "$s"
}

org_type=""
name=""
client_id=""
key_id=""
pem=""

if [[ $mode != key ]]; then
  read -r -p "Client ID: " client_id
  client_id=$(printf '%s' "$client_id" | tr -d '[:space:]')
  [[ $client_id =~ ^[A-Za-z0-9._-]+$ ]] || die "That doesn't look like a Client ID."

  case "$(printf '%s' "$client_id" | tr '[:lower:]' '[:upper:]')" in
    SCHOOLAPI.*) org_type=school ;;
    BUSINESSAPI.*) org_type=business ;;
    *)
      read -r -p "Organization type — school or business? " org_type
      org_type=$(printf '%s' "$org_type" | tr '[:upper:]' '[:lower:]')
      [[ $org_type == school || $org_type == business ]] || die "Enter school or business."
      ;;
  esac

  read -r -p "Key ID: " key_id
  key_id=$(printf '%s' "$key_id" | tr -d '[:space:]')
  [[ $key_id =~ ^[A-Za-z0-9-]+$ ]] || die "That doesn't look like a Key ID."

  read -r -p "Organization name (optional): " name
  [[ $name != *[[:cntrl:]]* ]] || die "The name contains control characters."
fi

if [[ $mode != details ]]; then
  read -r -p "Path to the .pem (you can drag the file here): " pem_path
  # Undo the quoting and escaping Terminal adds when a file is dragged in.
  pem_path=${pem_path%"${pem_path##*[![:space:]]}"}
  pem_path=${pem_path#[\'\"]}
  pem_path=${pem_path%[\'\"]}
  pem_path=${pem_path//\\ / }
  pem_path=${pem_path/#\~/$HOME}
  [[ -f $pem_path ]] || die "No file at $pem_path"

  openssl pkey -in "$pem_path" -noout -text 2>/dev/null | grep -Eq 'prime256v1|P-256' \
    || die "That file isn't a P-256 private key. Use the .pem downloaded when the API account was created."
  # Normalize to PKCS#8, which drops any EC PARAMETERS block and keeps the code small.
  pem=$(openssl pkey -in "$pem_path" 2>/dev/null) || die "Couldn't read the private key."
fi

if [[ $mode == key ]]; then
  payload=$pem
else
  payload="{\"orgType\":\"$org_type\""
  [[ -n $name ]] && payload+=",\"name\":$(json_string "$name")"
  payload+=",\"clientId\":\"$client_id\",\"keyId\":\"$key_id\""
  if [[ $mode == full ]]; then
    # The PEM is base64, dashes and spaces, so only its line breaks need escaping.
    payload+=",\"privateKey\":\"$(printf '%s' "$pem" | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }')\""
  fi
  payload+="}"
fi

echo
if [[ $mode != details ]]; then
  echo "⚠  This code contains your organization's private key. Treat it like the .pem file:"
  echo "   show it only to the technician who's scanning, and stop any screen sharing first."
  echo
fi
read -r -p "Press Return to show the code… " _

trap 'wipe; unset payload pem' EXIT
trap 'exit 130' INT TERM

wipe
printf '%s' "$payload" | qrencode -t ANSIUTF8 -l M -m 2
echo
echo "Scan in SerialSnap: Add organization › Scan setup QR code."
read -r -t 120 -p "Press Return when done (the screen clears automatically in 2 minutes). " _ || true
