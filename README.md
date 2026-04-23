# Local Server with Tailscale Setup

A bootstrap and configuration suite for setting up a self-hosted NAS with Docker containers, Tailscale networking, and optional Intel GPU support.

## bootstrap.sh

`bootstrap.sh` is an automated setup script that prepares a Debian system for hosting containerized services. It performs the following:

1. **OS Verification**: Verifies the system is running Debian before proceeding
2. **System Updates**: Updates and upgrades all system packages
3. **Directory Structure**: Creates essential working directories:
   - `~/trans/` (with `config/`, `downloads/`, and `complete/` subdirectories for torrent management)
   - System directories: `~/bin/`, `~/temp/`, `~/etc/`, `~/man/`, `~/not/`, `~/src/`, `~/vcs/`, `~/dta/`, `~/lib/`, `~/tst/`, `~/docker/`
4. **Ansible Installation**: Installs Ansible for configuration management
5. **Playbook Execution**: Runs `system_setup.yml` playbook with elevated privileges to set up Docker

After completion, the script adds the current user to the `docker` group for passwordless Docker access.

### system_setup.yml

`system_setup.yml` is an Ansible playbook that installs and configures Docker and development utilities on Debian systems. It:

- **Installs Prerequisites**: ca-certificates, curl, gnupg, lsb-release
- **Configures Docker Repository**: Adds the official Docker APT repository with GPG key verification
- **Installs Docker**: Docker CE, CLI, containerd, buildx plugin, and compose plugin
- **Installs Utilities**: tmux, htop, vim, tree, build-essential, rsync, git, unzip
- **Enables Services**: Starts and enables both Docker and containerd services
- **Configures User Access**: Optionally adds users to the docker group (configure via `docker_users` variable)

## Docker

This repository includes Docker Compose configurations for running self-hosted services. The main `docker-compose.yml` file orchestrates five containerized applications:

### docker-compose.yml Overview

The root `docker-compose.yml` includes and manages the following services:

#### Jellyfin
A free media system that functions as a personal streaming service. Runs on port 8096 and includes GPU access for hardware-accelerated transcoding. Features:
- Media server and streaming platform
- REST API for automating tasks
- Web interface for browsing and playing media
- Supports various media formats and codecs

#### SearXNG
A privacy-respecting metasearch engine that aggregates results from multiple search providers without storing user data. Runs on port 7070 and includes:
- Valkey (Redis-compatible) cache backend for improved performance
- Configurable search providers and result filtering
- Web-based search interface
- No tracking or profiling of user searches

#### Transmission
A lightweight BitTorrent client with a web interface for remote management. Provides:
- Torrent downloading via web UI (port 9091)
- Configuration and monitoring of torrents
- Integration with the transmission directory structure (`~/trans/config`, `~/trans/downloads`, `~/trans/complete`)
- Peer port listening (51413 TCP/UDP)

#### Paperless
A document management system that organizes and digitizes paper documents. Features:
- Document scanning and OCR capabilities
- PostgreSQL database backend for robust data storage
- File import/export functionality
- Full-text search and document tagging
- Runs on port 8000

#### DokuWiki
A lightweight wiki engine suitable for documentation and knowledge bases. Provides:
- Web-based wiki with simple markup syntax
- User authentication and permissions
- Revision history and change tracking
- No database required (file-based storage)
- Runs on ports 8080 (HTTP) and 8443 (HTTPS)

### Managing Containers

To start all services, run:
```bash
docker compose up -d
```

To stop all services:
```bash
docker compose down
```

To view logs:
```bash
docker compose logs -f [service-name]
```

Edit parameters in the respective service folders before running `docker compose up -d` within each folder. You can modify environment variables, ports, and volumes by editing the `docker-compose.yml` and `.env` files in each service directory. Restart the service with `docker compose down` followed by `docker compose up -d` after making changes.

Refer to the [Docker Compose documentation](https://docs.docker.com/compose) for additional operations and advanced configuration.

## tailscale.sh

`tailscale.sh` is an automated script that configures Tailscale networking for your server, enabling secure remote access and subnet routing. It performs the following:

1. **Operator Configuration**: Sets the current user as a Tailscale operator
2. **IP Forwarding**: Enables IPv4 and IPv6 forwarding for subnet routing:
   - Creates `/etc/sysctl.d/99-tailscale.conf` with forwarding rules
   - Applies sysctl configuration changes
3. **Tailscale Advertising**: Configures the server as an exit node and advertises local subnets:
   - `192.168.1.0/24` - Local network (adjust for your configuration)
   - `172.17.0.0/16` - Docker default bridge network
   - `172.18.0.0/16` - Docker custom networks
4. **Service Port Exposure**: Exposes container ports via Tailscale using `tailscale serve`:
   - Port 8096 (Jellyfin media server)
   - Port 7359 (Jellyfin discovery/DLNA)
   - Port 8080 (DokuWiki web interface)
   - Port 9091 (Transmission web UI)
   - Port 7070 (SearXNG search engine)
5. **Service Restart**: Restarts the Tailscale daemon and displays current network status

With Tailscale configured, you can access your services from anywhere through your tailnet domain. Use `tailscale status` for network diagnostics.

### Tailscale Networking Notes

- **MagicDNS**: By default, Tailscale provides one subdomain per device. The `tailscale serve` command exposes services via their ports on your Tailscale IP.
- **Multiple Subdomains**: For handling multiple subdomains, configure an external DNS service to point additional subdomains to your server's Tailscale IP (not critical for home server use).
- **Subnets**: Setting up subnets along with an exit node is recommended for routing local network traffic through Tailscale.

## intel.sh

`intel.sh` is a diagnostic and driver installation script for systems with Intel integrated GPUs. It automates GPU detection and hardware acceleration setup. The script:

1. **GPU Detection**: Searches for Intel integrated graphics (VGA, Display, or 3D class devices)
2. **Generation Verification**: Confirms the GPU is Gen8+ (Broadwell 2014 or newer) by checking the PCI device ID
3. **VA-API Installation**: Installs video acceleration drivers for modern Intel iGPUs:
   - `intel-media-va-driver` - Intel Media Driver for VA-API
   - `i965-va-driver` - Intel i965 Video Driver (legacy support)
   - `vainfo` - VA-API diagnostic tool
4. **Verification**: Runs `vainfo` to confirm the installation and display available video formats

This enables hardware-accelerated video encoding and decoding in applications like Jellyfin, improving performance and reducing CPU usage during media transcoding.

### Troubleshooting

If your Intel GPU is not detected, verify:
- The GPU is recognized: `lspci | grep -i "VGA\|Display\|3D"`
- The GPU generation is Broadwell or newer (Gen8+)

For more details on VA-API and Intel video drivers, refer to the [Intel Media Driver documentation](https://github.com/intel/media-driver).

## Docker Startup Issues

If Docker containers fail to start due to network connectivity issues, you may need to adjust the systemd service ordering. This ensures Docker starts after the network is available:

```bash
sudo EDITOR=vim systemctl edit docker
```

Add or uncomment the following lines in the `[Unit]` section:

```ini
[Unit]
After=network-online.target
Wants=network-online.target
```

Save and exit, then reload and restart the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

This is particularly important when using Tailscale or other network services that need to be initialized before Docker starts.