#!/bin/bash
#
# Docker Installation Script for Oracle Enterprise Linux
# Supports OEL 7, 8, and 9
#
# Usage:
#   sudo ./setup-docker-el.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_info "Docker Installation for Oracle Enterprise Linux"
echo "=================================================="
echo ""

# Detect OS version
if [[ -f /etc/oracle-release ]]; then
    OS_VERSION=$(grep -oP '(?<=release )[0-9]+' /etc/oracle-release)
    print_info "Detected Oracle Linux $OS_VERSION"
else
    print_error "This script is for Oracle Enterprise Linux only"
    exit 1
fi

# Update system
print_info "Updating system packages..."
dnf update -y

# Install prerequisites
print_info "Installing prerequisites..."
dnf install -y dnf-utils device-mapper-persistent-data lvm2 \
    net-tools tcpdump vim curl wget

# Add Docker CE repository
print_info "Adding Docker CE repository..."
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker CE
print_info "Installing Docker CE..."
dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Configure Docker daemon
print_info "Configuring Docker daemon..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "data-root": "/var/lib/docker",
  "live-restore": true,
  "userland-proxy": false
}
EOF

# Apply VoIP kernel optimizations
print_info "Applying VoIP kernel parameters..."
cat > /etc/sysctl.d/99-voip-tuning.conf <<EOF
# VoIP/SIPp Performance Tuning
# High UDP buffer sizes for RTP
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 262144
net.core.wmem_default = 262144

# UDP memory
net.ipv4.udp_mem = 65536 131072 262144

# Increase max packet backlog
net.core.netdev_max_backlog = 300000

# Port range
net.ipv4.ip_local_port_range = 1024 65535

# File descriptors
fs.file-max = 2097152

# Connection tracking (if using iptables/firewalld)
net.netfilter.nf_conntrack_max = 1000000
EOF

sysctl -p /etc/sysctl.d/99-voip-tuning.conf 2>/dev/null || true

# Configure SELinux for Docker
if command -v getenforce >/dev/null 2>&1; then
    if [[ "$(getenforce)" != "Disabled" ]]; then
        print_info "Configuring SELinux for Docker..."
        setsebool -P container_manage_cgroup on
        print_success "SELinux configured"
    fi
fi

# Configure firewall
if systemctl is-active --quiet firewalld; then
    print_info "Configuring firewall for SIPp..."

    # SIP signaling
    firewall-cmd --permanent --add-port=5060-5100/udp --zone=public
    firewall-cmd --permanent --add-port=5060-5100/tcp --zone=public

    # RTP media
    firewall-cmd --permanent --add-port=16384-32768/udp --zone=public

    # SIPp control
    firewall-cmd --permanent --add-port=8888/tcp --zone=public

    # Docker
    firewall-cmd --permanent --zone=trusted --add-interface=docker0 2>/dev/null || true

    firewall-cmd --reload
    print_success "Firewall configured"
fi

# Enable and start Docker
print_info "Enabling and starting Docker service..."
systemctl enable docker
systemctl start docker

# Add current user to docker group (if script was run with sudo)
if [[ -n "$SUDO_USER" ]]; then
    print_info "Adding user $SUDO_USER to docker group..."
    usermod -aG docker $SUDO_USER
    print_warning "User $SUDO_USER added to docker group. Log out and back in for this to take effect."
fi

# Verify installation
print_info "Verifying Docker installation..."
docker --version

print_success "Docker installation completed successfully!"
echo ""
echo "Next steps:"
echo "  1. Log out and back in (if user was added to docker group)"
echo "  2. Test: docker run hello-world"
echo "  3. Build SIPp image: cd /path/to/jast && docker build -t sipp:3.7.3 ."
echo "  4. Configure .env file with your settings"
echo "  5. Run: ./sipp-control.sh"
echo ""
print_info "System information:"
echo "  Docker version: $(docker --version)"
echo "  Docker Compose: $(docker compose version)"
echo "  Storage driver: $(docker info --format '{{.Driver}}')"
echo ""
