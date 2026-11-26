#!/bin/bash

# Script to create OpenVPN client certificates

if [ -z "$1" ]; then
    echo "Usage: ./create-client.sh CLIENT_NAME"
    echo "Example: ./create-client.sh john-laptop"
    exit 1
fi

CLIENT_NAME=$1

echo "Creating client certificate for: $CLIENT_NAME"

# Generate client certificate without password
docker run -v $PWD/openvpn-data/conf:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full $CLIENT_NAME nopass

# Retrieve the client configuration
docker run -v $PWD/openvpn-data/conf:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient $CLIENT_NAME > $CLIENT_NAME.ovpn

echo ""
echo "✓ Client certificate created successfully!"
echo "✓ Configuration file: $CLIENT_NAME.ovpn"
echo ""
echo "Send this .ovpn file to your client and import it into OpenVPN client software."
echo ""
echo "Common OpenVPN clients:"
echo "  - Windows/Mac/Linux: OpenVPN Connect"
echo "  - Android: OpenVPN for Android"
echo "  - iOS: OpenVPN Connect"