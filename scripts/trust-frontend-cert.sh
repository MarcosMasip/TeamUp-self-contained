#!/usr/bin/env bash
set -euo pipefail

# Helper script to trust the Angular dev-server self-signed certificate (macOS & Linux).
# This reduces or removes the browser warning when using HTTPS mode (FRONTEND_SSL=1).
# For Windows, import the certificate into the Trusted Root Certification Authorities store manually.

CERT_PATH="socialnetworkingapp-front/src/ssl/server.crt"

if [ ! -f "$CERT_PATH" ]; then
  echo "Certificate not found at $CERT_PATH" >&2
  exit 1
fi

echo "Exporting certificate to temporary DER format..."
TMP_DER=$(mktemp /tmp/teamup-cert-XXXX.der)
openssl x509 -in "$CERT_PATH" -outform der -out "$TMP_DER"

UNAME=$(uname -s || echo unknown)
case "$UNAME" in
  Darwin)
    echo "Adding cert to macOS System keychain (requires sudo)..."
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CERT_PATH" || {
      echo "Failed to add certificate. You may need to unlock Keychain Access and retry." >&2
      exit 1
    }
    echo "Certificate trusted. You may need to restart your browser.";;
  Linux)
    # Attempt to detect update-ca-certificates (Debian/Ubuntu) or trust anchors (Fedora/RHEL)
    if command -v update-ca-certificates >/dev/null 2>&1; then
      echo "Installing certificate into /usr/local/share/ca-certificates (requires sudo)..."
      sudo cp "$CERT_PATH" /usr/local/share/ca-certificates/teamup-frontend.crt
      sudo update-ca-certificates
      echo "Certificate installed. Restart browser.";
    elif [ -d /etc/pki/ca-trust/source/anchors ]; then
      echo "Installing certificate into /etc/pki/ca-trust/source/anchors (requires sudo)..."
      sudo cp "$CERT_PATH" /etc/pki/ca-trust/source/anchors/teamup-frontend.crt
      sudo update-ca-trust extract
      echo "Certificate installed. Restart browser.";
    else
      echo "Could not detect a supported CA trust update mechanism. Please add $CERT_PATH manually." >&2
      exit 2
    fi;;
  *)
    echo "Unsupported OS for automatic trust. Please add $CERT_PATH manually." >&2
    exit 3;;
esac

echo "Done."