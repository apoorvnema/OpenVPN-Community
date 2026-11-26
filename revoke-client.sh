#!/bin/bash

# Script to revoke OpenVPN client certificates

if [ -z "$1" ]; then
    echo "Usage: ./revoke-client.sh CLIENT_NAME"
    echo "Example: ./revoke-client.sh john-laptop"
    exit 1
fi

CLIENT_NAME=$1

echo "Revoking client certificate for: $CLIENT_NAME"

# Warn the user
read -p "Are you sure you want to revoke $CLIENT_NAME? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Revocation cancelled."
    exit 1
fi

# Revoke the certificate
# The 'remove' argument deletes the client's keys/certs from the server's PKI store
docker run -v $PWD/openvpn-data/conf:/etc/openvpn --rm -it kylemanna/openvpn ovpn_revokeclient $CLIENT_NAME remove

# Remove the local config file if it exists
if [ -f "$CLIENT_NAME.ovpn" ]; then
    rm "$CLIENT_NAME.ovpn"
    echo "✓ Local configuration file $CLIENT_NAME.ovpn removed."
fi

echo ""
echo "✓ Client certificate '$CLIENT_NAME' has been revoked."
echo "✓ The client will no longer be able to connect."
echo ""
echo "Note: The server automatically picks up CRL changes, but you can restart "
echo "the container to be absolutely sure: docker-compose restart openvpn"
