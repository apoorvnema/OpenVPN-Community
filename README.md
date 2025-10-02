# Docker OpenVPN Server Setup

This repository contains scripts to easily set up an OpenVPN server using Docker containers. It supports multiple cloud providers and makes it simple to manage client certificates.

## Prerequisites

- Docker and Docker Compose installed on your server
- A cloud VM/instance with ports opened:
  - UDP 1194 (OpenVPN)
- Bash shell environment

## Supported Cloud Providers

- Amazon Web Services (AWS)
- Google Cloud Platform (GCP)
- Microsoft Azure
- Oracle Cloud Infrastructure (OCI)
- DigitalOcean
- And others (manual IP input available)

## Quick Start

1. Clone this repository to your server:
   ```bash
   git clone https://github.com/apoorvnema/OpenVPN-Community.git
   cd OpenVPN-Community
   ```

2. Make the scripts executable:
   ```bash
   chmod +x setup-openvpn.sh create-client.sh
   ```

3. Run the setup script:
   ```bash
   ./setup-openvpn.sh
   ```
   - Choose your cloud provider when prompted
   - Set a passphrase for the PKI when asked (remember this!)

4. Create a client certificate:
   ```bash
   ./create-client.sh client-name
   ```
   Replace `client-name` with your desired client identifier (e.g., laptop, phone, etc.)

5. Find your client configuration:
   - The script will create a file named `client-name.ovpn`
   - Transfer this file securely to your client device

## Client Setup

1. Install an OpenVPN client on your device:
   - **Windows/Mac/Linux**: [OpenVPN Connect](https://openvpn.net/client/)
   - **Android**: [OpenVPN for Android](https://play.google.com/store/apps/details?id=de.blinkt.openvpn)
   - **iOS**: [OpenVPN Connect](https://apps.apple.com/app/openvpn-connect/id590379981)

2. Import the `.ovpn` file into your OpenVPN client

3. Connect to your VPN server

## Management

- To create additional client certificates:
  ```bash
  ./create-client.sh another-client
  ```

- Each client gets their own `.ovpn` file
- Keep these files secure as they contain the certificates needed to connect to your VPN

## Security Notes

- Store the PKI passphrase safely
- Keep `.ovpn` files secure
- Each client should have their own certificate
- Revocation process is not included in these basic scripts

## License

This project uses the [kylemanna/openvpn](https://github.com/kylemanna/docker-openvpn) Docker image which is licensed under the GNU General Public License v2.0 (GPL-2.0). As such, this project is also distributed under the terms of GNU General Public License v2.0.

The setup and configuration scripts in this repository that wrap the Docker image are also licensed under GPL-2.0 to maintain license compatibility.

## Contributing

Feel free to open issues or submit pull requests for improvements.