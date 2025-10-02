#!/bin/bash

# OpenVPN Setup Script for AWS EC2
# This script sets up OpenVPN server with management capabilities

set -e

echo "=== OpenVPN AWS Setup Script ==="

# Get EC2 public IP automatically
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
echo "Detected Public IP: $PUBLIC_IP"

# Create directory structure
mkdir -p openvpn-data/conf

# Step 1: Initialize OpenVPN configuration
echo "Step 1: Initializing OpenVPN configuration..."
docker run -v $PWD/openvpn-data/conf:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://$PUBLIC_IP

# Step 2: Generate PKI (certificates and keys)
echo "Step 2: Generating PKI (you'll need to set a passphrase)..."
docker run -v $PWD/openvpn-data/conf:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki

# Step 3: Start the OpenVPN server
echo "Step 3: Starting OpenVPN server..."
docker-compose up -d openvpn

echo ""
echo "=== OpenVPN Server is Running! ==="
echo ""
echo "To create a client certificate, run:"
echo "  ./create-client.sh CLIENT_NAME"
echo ""
echo "Server IP: $PUBLIC_IP"
echo "Server Port: 1194/udp"
echo ""
echo "Make sure to open port 1194/udp in your AWS Security Group!"