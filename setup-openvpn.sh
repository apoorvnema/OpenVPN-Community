#!/bin/bash

# OpenVPN Setup Script for AWS EC2
# This script sets up OpenVPN server with management capabilities

set -e

echo "=== OpenVPN AWS Setup Script ==="

# Function to get public IP based on cloud provider
get_public_ip() {
    local provider=$1
    case $provider in
        "aws")
            curl -s http://checkip.amazonaws.com
            ;;
        "gcp")
            curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip
            ;;
        "azure")
            curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2021-02-01&format=text"
            ;;
        "oci")
            curl -s http://169.254.169.254/opc/v1/vnics/0/publicIp
            ;;
        "digitalocean")
            curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
}

# Ask for cloud provider
echo "Please select your cloud provider:"
echo "1) AWS (Amazon Web Services)"
echo "2) GCP (Google Cloud Platform)"
echo "3) Azure (Microsoft Azure)"
echo "4) OCI (Oracle Cloud Infrastructure)"
echo "5) DigitalOcean"
echo "6) Other (manual input)"
read -p "Enter choice (1-6): " choice

case $choice in
    1) provider="aws" ;;
    2) provider="gcp" ;;
    3) provider="azure" ;;
    4) provider="oci" ;;
    5) provider="digitalocean" ;;
    6) provider="manual" ;;
    *) 
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

if [ "$provider" = "manual" ]; then
    read -p "Please enter your server's public IP address: " PUBLIC_IP
else
    PUBLIC_IP=$(get_public_ip $provider)
    if [ -z "$PUBLIC_IP" ]; then
        echo "Could not automatically detect IP. Please enter manually:"
        read -p "Server's public IP address: " PUBLIC_IP
    fi
fi

echo "Using Public IP: $PUBLIC_IP"

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