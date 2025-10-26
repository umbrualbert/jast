# JAST - Just Another SIP Tester

Enterprise-grade SIPp load testing framework with Docker orchestration for SBC (Session Border Controller) testing and VoIP validation.

[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://www.docker.com/)
[![SIPp](https://img.shields.io/badge/SIPp-3.7.3-green.svg)](https://github.com/SIPp/sipp)
[![TLS](https://img.shields.io/badge/TLS-enabled-blue.svg)](TLS_GUIDE.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Architecture](#architecture)
- [Scenarios](#scenarios)
- [Configuration](#configuration)
- [Advanced Usage](#advanced-usage)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Features

✅ **74+ Pre-built Test Scenarios**
- UAC (User Agent Client) and UAS (User Agent Server) scenarios
- Multiple codec support (G.711, G.722, G.729, H.264)
- Registration, subscription, presence, call transfer
- Error injection and edge case testing

✅ **Docker-First Design**
- Pre-built Docker images for instant deployment
- Docker Compose for multi-container orchestration
- Network isolation with bridge networks
- Resource limits and CPU pinning support

✅ **Menu-Driven Control System**
- Interactive CLI for easy scenario selection
- Remote command execution support
- Real-time monitoring dashboard
- Automated test execution

✅ **SBC Load Testing**
- Multi-container UAC/UAS groups
- Progressive load testing (10-200+ CPS)
- Long-duration stability tests (17+ minutes)
- Codec transcoding validation

✅ **RTP Media Support**
- 11 pre-recorded PCAP media files
- Dynamic PCAP playback (patched SIPp)
- RTP echo mode for media validation
- DTMF and FAX support

✅ **TLS/SIPS Support** ⭐ NEW
- Full TLS/SSL encryption (OpenSSL 1.1.0+)
- SIPS (SIP over TLS) on port 5061
- Self-signed and CA-signed certificates
- TLS key logging for Wireshark decryption
- SCTP transport support

✅ **Enterprise Features**
- Oracle Enterprise Linux support
- Systemd integration
- Firewall configuration
- VoIP kernel tuning
- Resource monitoring

---

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/jast.git
cd jast
```

### 2. Build Docker Image

```bash
make build
# or manually:
docker build -t sipp:3.7.3 .
```

**Note**: Image includes SIPp 3.7.3 with TLS/SSL, SCTP, PCAP, and GSL support

### 3. Configure Environment

```bash
make init
# Edit .env with your SBC IP and settings
vim .env
```

### 4. Run Interactive Menu

```bash
make menu
# or directly:
./sipp-control.sh
```

### 5. Start Testing!

**Option A: Interactive Mode**
```bash
./sipp-control.sh
# Select "2. Run UAC Test"
# Choose scenario and configure parameters
```

**Option B: Command Line**
```bash
# Quick test
./sipp-control.sh run-uac sipp_uac_basic.xml 192.168.1.100 10 100

# With G.711 media
./sipp-control.sh run-uac sipp_uac_pcap_g711a.xml 192.168.1.100 20 500
```

**Option C: Docker Compose**
```bash
# Edit .env first
export SBC_IP=192.168.1.100
export UAC_CPS=10

# Start containers
make up-sbc

# Monitor
make monitor
```

---

## Installation

### Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)
- Linux system (Ubuntu, CentOS, Oracle Linux)
- 4+ GB RAM
- 100+ GB disk space

### Oracle Enterprise Linux Setup

Automated installation script provided:

```bash
# Install Docker on Oracle Linux 7/8/9
sudo ./scripts/setup-docker-el.sh

# This will:
# - Install Docker CE
# - Configure VoIP kernel parameters
# - Set up firewall rules
# - Enable Docker service
```

### Manual Docker Installation

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
```

**CentOS/RHEL:**
```bash
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker
```

### Build SIPp Image

```bash
# Using Makefile
make build

# Or manually
docker build -t sipp:3.7.3 .

# Verify
docker images | grep sipp
```

---

## Usage

### Method 1: Interactive Menu System

The easiest way to run tests:

```bash
./sipp-control.sh
```

Features:
- Browse and select from 74 scenarios
- Configure test parameters interactively
- View real-time logs
- Monitor container status
- View statistics

### Method 2: Command Line (Remote Execution)

Perfect for automation and SSH:

```bash
# List scenarios
./sipp-control.sh list-scenarios

# Run UAC test
./sipp-control.sh run-uac <scenario> <target_ip> [cps] [max_calls] [total_calls]

# Examples:
./sipp-control.sh run-uac sipp_uac_basic.xml 192.168.1.100 10 100 1000
./sipp-control.sh run-uac sipp_uac_pcap_g711a.xml 10.0.0.1 50 500 10000

# Run UAS server
./sipp-control.sh run-uas sipp_uas_basic.xml 192.168.1.50 5060

# Check status
./sipp-control.sh status

# View logs
./sipp-control.sh logs sipp-uac-basic-12345

# Stop all
./sipp-control.sh stop-all
```

### Method 3: Docker Compose

For multi-container deployments:

```bash
# Basic deployment (1 UAC, 1 UAS)
make up

# SBC testing (multiple UAC/UAS containers)
make up-sbc

# With advanced scenarios
make up-advanced

# All scenarios (stress, registration, etc.)
make up-all

# Custom environment
SBC_IP=10.0.0.1 UAC_CPS=100 make up-sbc
```

### Method 4: Direct Docker Run

Low-level control:

```bash
# UAC (Client)
docker run -d --name sipp-uac \
  --network host \
  -v $(pwd)/scens:/scens:ro \
  -v $(pwd)/logs:/logs \
  -e ARGS="-sf /scens/sipp_uac_basic.xml -r 10 -m 100 192.168.1.100:5060" \
  sipp:3.7.3

# UAS (Server)
docker run -d --name sipp-uas \
  --network host \
  -v $(pwd)/scens:/scens:ro \
  -v $(pwd)/logs:/logs \
  -e ARGS="-sf /scens/sipp_uas_basic.xml -rtp_echo" \
  sipp:3.7.3
```

---

## Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│              Oracle Enterprise Linux Host                    │
│                                                               │
│  ┌──────────────┐         ┌─────────┐         ┌───────────┐ │
│  │ UAC Group    │  SIP    │   SBC   │  SIP    │ UAS Group │ │
│  │ (172.20.x.x) ├────────>│   DUT   │<────────┤(172.21.x.x)│ │
│  │              │  RTP    │         │  RTP    │           │ │
│  │ - uac-g711   │         └─────────┘         │ - uas-g711│ │
│  │ - uac-g722   │                             │ - uas-multi│ │
│  │ - uac-long   │                             │ - uas-basic│ │
│  └──────────────┘                             └───────────┘ │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Port Allocation

| Component | Ports | Protocol | Purpose |
|-----------|-------|----------|---------|
| SIP Signaling | 5060-5100 | UDP/TCP | SIP messages |
| RTP Media | 16384-32768 | UDP | Audio/video streams |
| RTCP Control | 16385-32769 | UDP | RTP control (odd ports) |
| SIPp Stats | 8888 | TCP | Statistics port |

### Directory Structure

```
jast/
├── sipp-control.sh              # Main control script
├── Makefile                     # Common operations
├── docker-compose.yml           # Basic deployment
├── docker-compose-sbc-test.yml  # SBC testing
├── .env.example                 # Configuration template
├── Dockerfile                   # SIPp image
│
├── scens/                       # 74 test scenarios
│   ├── README.md                # Scenario catalog
│   ├── sipp_uac_*.xml           # UAC scenarios
│   ├── sipp_uas_*.xml           # UAS scenarios
│   ├── *.pcap                   # Media files
│   └── *.csv                    # Test data
│
├── scripts/
│   ├── setup-docker-el.sh       # Docker installation
│   ├── monitor.sh               # Real-time monitoring
│   ├── run_sipp.sh              # Container entrypoint
│   └── load.sh                  # Load control
│
└── logs/                        # Test logs and statistics
```

---

## Scenarios

### Quick Reference

| Category | Scenarios | Use Case |
|----------|-----------|----------|
| **Basic** | `sipp_uac_basic.xml`, `sipp_uas_basic.xml` | Connectivity testing |
| **G.711** | `sipp_uac_pcap_g711a.xml` | Most common codec |
| **G.722** | `sipp_uac_pcap_g722.xml` | Wideband audio |
| **G.729** | `uac_g711_34sec-G729.xml` | Compressed audio |
| **Video** | `sipp_uac_pcap_h264.xml` | H.264 video calls |
| **Long** | `17minutes_G711.xml` | Stability testing |
| **Register** | `sipp_uac_register.xml` | Registration load |
| **Errors** | `sipp_uac_bad_message.xml` | Error handling |

**Full catalog**: See [scens/README.md](scens/README.md) for all 74 scenarios.

### Scenario Categories

1. **Basic Call Flows** - INVITE/200/ACK/BYE
2. **Codec Testing** - G.711, G.722, G.729, H.264
3. **SDP Handling** - Various SDP configurations
4. **Call Hold/Resume** - sendonly/recvonly/inactive
5. **Re-INVITE** - Mid-call modifications
6. **Registration** - REGISTER with authentication
7. **Subscription** - Presence, MWI
8. **Transfer** - REFER method
9. **Error Injection** - Malformed messages, edge cases
10. **Advanced** - SBC-specific, complex scenarios

---

## Configuration

### Environment Variables (.env)

```bash
# Copy template
cp .env.example .env

# Edit configuration
vim .env
```

**Key Settings:**

```bash
# SBC Configuration
SBC_IP=192.168.1.100
SBC_PORT=5060

# UAC Settings
UAC_CPS=10                    # Calls per second
UAC_MAX_CALLS=100             # Concurrent calls
UAC_TOTAL_CALLS=1000          # Total calls

# Resource Limits
CPU_LIMIT=2.0
MEMORY_LIMIT=2G

# Logging
TRACE_ERR=true
TRACE_STAT=true
```

### SIPp Command Parameters

Common parameters used in scenarios:

```
-sf <file>        Scenario file
-r <rate>         Call rate (CPS)
-m <max>          Max concurrent calls
-l <limit>        Total call limit
-d <duration>     Call duration (ms)

-i <ip>           Local IP
-mi <ip>          Media IP
-mp <port>        Media port base
-p <port>         SIP port

-inf <csv>        Inject CSV data
-rtp_echo         Echo RTP back
-trace_err        Log errors only
-trace_stat       Generate statistics
```

---

## Advanced Usage

### Multi-Container Load Testing

```bash
# Start SBC test environment
docker compose -f docker-compose-sbc-test.yml up -d

# This starts:
# - uac-g711 (172.20.1.10)
# - uas-g711 (172.21.1.10)
# - uas-basic (172.21.1.12)

# Scale UAC containers
docker compose -f docker-compose-sbc-test.yml up -d --scale uac-g711=5

# Custom CPS
UAC_CPS=100 docker compose -f docker-compose-sbc-test.yml up -d
```

### Progressive Load Testing

```bash
# Phase 1: Baseline (10 CPS)
./sipp-control.sh run-uac sipp_uac_basic.xml 192.168.1.100 10 100 1000

# Phase 2: Moderate (50 CPS)
./sipp-control.sh run-uac sipp_uac_basic.xml 192.168.1.100 50 500 5000

# Phase 3: High (100 CPS)
./sipp-control.sh run-uac sipp_uac_basic.xml 192.168.1.100 100 1000 10000

# Phase 4: Stress (200 CPS)
./sipp-control.sh run-uac sipp_uac_basic.xml 192.168.1.100 200 2000 20000
```

### Long-Duration Stability Testing

```bash
# 17-minute calls for 24 hours
./sipp-control.sh run-uac 17minutes_G711.xml 192.168.1.100 5 50

# With CSV data injection
docker run -d --network host \
  -v $(pwd)/scens:/scens:ro \
  -e ARGS="-sf /scens/17minutes_G711.xml \
           -inf /scens/2numbers.csv \
           -r 5 -m 50 -d 1020000 \
           192.168.1.100:5060" \
  sipp:3.7.3
```

### Codec Transcoding Tests

```bash
# UAC offers G.711, UAS expects G.729
# (SBC must transcode)

# Start UAS with G.729 expectation
./sipp-control.sh run-uas sipp_uas_basic.xml 172.21.1.1 5060

# Start UAC with G.711
./sipp-control.sh run-uac sipp_uac_pcap_g711a.xml 192.168.1.100 10 100

# Monitor SBC for transcoding activity
```

---

## Monitoring

### Real-Time Dashboard

```bash
# Start monitoring
make monitor

# Or directly
./scripts/monitor.sh watch
```

Features:
- Container status
- CPU/Memory usage
- Network I/O
- Error summary
- SIPp statistics

### View Logs

```bash
# All containers
make logs

# Specific container
make logs-uac
make logs-uas

# Using control script
./sipp-control.sh logs sipp-uac-g711
```

### Statistics

SIPp generates CSV statistics:

```bash
# Location
ls -la logs/*-stats.csv

# View with column formatting
cat logs/sipp-uac-basic-12345-stats.csv | column -t -s ';'

# Key metrics:
# - Total calls
# - Successful calls
# - Failed calls
# - Retransmissions
# - Call rate (CPS)
```

### Resource Usage

```bash
# Current usage
make stats

# Continuous monitoring
docker stats

# System resources
./scripts/monitor.sh system
```

---

## Troubleshooting

### Common Issues

**1. No RTP Media**

```bash
# Check media ports
netstat -an | grep 16384

# Verify PCAP file exists
docker exec sipp-uac-1 ls /scens/*.pcap

# Check SDP in packet capture
tcpdump -i any -s0 -A port 5060
```

**2. High Packet Loss**

```bash
# Increase UDP buffers
sudo sysctl -w net.core.rmem_max=134217728

# Check system load
top

# Reduce logging
# Use -trace_err instead of -trace_msg
```

**3. Call Failures at High CPS**

```bash
# Increase file descriptors
ulimit -n 65535

# Tune SIPp performance
-max_recv_loops 1000 -max_sched_loops 1000

# Check SBC capacity
# Review SBC logs and metrics
```

**4. Container Won't Start**

```bash
# Check logs
docker logs sipp-uac-1

# Verify scenario file
docker exec sipp-uac-1 cat /scens/sipp_uac_basic.xml

# Check ARGS environment variable
docker inspect sipp-uac-1 | grep ARGS
```

### Debug Mode

```bash
# Enable verbose logging
docker run --rm --network host \
  -e ARGS="-sf /scens/sipp_uac_basic.xml -trace_msg -trace_err 192.168.1.100:5060" \
  sipp:3.7.3

# Packet capture
sudo tcpdump -i any -w debug.pcap 'udp port 5060 or portrange 16384-32768'
```

---

## Performance Tuning

### Kernel Parameters

```bash
# Applied by setup-docker-el.sh
# Manual tuning:

sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728
sudo sysctl -w net.core.netdev_max_backlog=300000
sudo sysctl -w fs.file-max=2097152
```

### Docker Resource Limits

```yaml
# In docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '4.0'
      memory: 4G
    reservations:
      cpus: '2.0'
      memory: 2G
```

### SIPp Optimization

```bash
# Minimize I/O
-trace_err (not -trace_msg)

# Increase processing loops
-max_recv_loops 1000
-max_sched_loops 1000

# Adjust timer resolution
-timer_resol 10 (default: 1)
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: SIPp Load Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build SIPp Image
        run: make build
      - name: Run Basic Test
        run: make ci-test
      - name: Upload Logs
        uses: actions/upload-artifact@v2
        with:
          name: sipp-logs
          path: logs/
```

### Command Line

```bash
# Run CI test
make ci-test

# This executes:
# 1. Build image
# 2. Run basic UAC test
# 3. Check for errors
# 4. Exit with code 0 (pass) or 1 (fail)
```

---

## Remote Execution

Perfect for SSH automation:

```bash
# SSH to test server
ssh user@test-server

# Run test remotely
./sipp-control.sh run-uac sipp_uac_basic.xml 192.168.1.100 10 100 1000

# Check status
./sipp-control.sh status

# View stats
./sipp-control.sh stats

# Stop all
./sipp-control.sh stop-all
```

### Ansible Playbook Example

```yaml
- name: Run SIPp Load Test
  hosts: sipp-servers
  tasks:
    - name: Start UAC test
      command: ./sipp-control.sh run-uac sipp_uac_basic.xml {{ sbc_ip }} 50 500 10000
      args:
        chdir: /opt/jast

    - name: Wait for completion
      wait_for:
        timeout: 300

    - name: Collect stats
      fetch:
        src: /opt/jast/logs/
        dest: /tmp/sipp-results/
```

---

## Makefile Commands

Quick reference of all `make` commands:

```bash
make help           # Show all commands
make build          # Build Docker image
make up             # Start basic containers
make up-sbc         # Start SBC test containers
make down           # Stop all containers
make status         # Show container status
make logs           # View logs
make monitor        # Real-time monitoring
make clean          # Clean up containers
make scenarios      # List all scenarios
make menu           # Interactive menu
make test-basic     # Run basic test
make info           # System information
```

---

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new scenarios
4. Update documentation
5. Submit pull request

### Adding New Scenarios

```bash
# Create scenario file
vim scens/my_new_scenario.xml

# Test it
./sipp-control.sh run-uac my_new_scenario.xml 192.168.1.100

# Document in scens/README.md
```

---

## License

MIT License - See [LICENSE](LICENSE) file

---

## Support

- **Issues**: https://github.com/yourusername/jast/issues
- **Documentation**: See `docs/` directory
- **Scenario Catalog**: [scens/README.md](scens/README.md)

---

## Acknowledgments

- **SIPp**: https://github.com/SIPp/sipp
- **Dynamic PCAP Patch**: Enables repeated PCAP playback
- **Community**: Thanks to all contributors!

---

## Quick Reference Card

```bash
# Setup
make setup                                    # Complete setup
make build                                    # Build image
make init                                     # Create .env

# Run Tests
make menu                                     # Interactive menu
./sipp-control.sh run-uac <scenario> <ip>    # CLI test
make up-sbc                                   # Docker Compose

# Monitor
make status                                   # Container status
make monitor                                  # Real-time dashboard
make logs                                     # View logs

# Cleanup
make clean                                    # Remove containers
make clean-logs                               # Remove logs

# Info
make scenarios                                # List scenarios
make info                                     # System info
make help                                     # Show help
```

---

**Version**: 2.0.0 (TLS-Enabled)
**Last Updated**: 2025-10-26
**SIPp Version**: 3.7.3
**Features**: TLS/SSL, SCTP, PCAP, GSL
**Scenarios**: 74+ (including TLS/SIPS)
**PCAP Files**: 11
**TLS Guide**: [TLS_GUIDE.md](TLS_GUIDE.md)
