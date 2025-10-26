# Quick Start Guide - JAST SIPp Testing

**Get started with SIPp load testing in 5 minutes!**

## Prerequisites

- Oracle Enterprise Linux (or Ubuntu/CentOS)
- Root/sudo access
- Network access to your SBC

---

## 1. Install Docker (Oracle Linux)

```bash
# Automated installation
cd /path/to/jast
sudo ./scripts/setup-docker-el.sh

# Logout and login for docker group to take effect
exit
# SSH back in
```

---

## 2. Build SIPp Image

```bash
cd /path/to/jast

# Quick build
make build

# Verify
docker images | grep sipp
```

---

## 3. Configure Your Environment

```bash
# Create configuration file
make init

# Edit with your SBC details
vim .env
```

**Minimum required settings:**
```bash
SBC_IP=192.168.1.100     # Your SBC IP address
SBC_PORT=5060            # Your SBC SIP port
```

---

## 4. Run Your First Test

### Option A: Interactive Menu (Easiest)

```bash
make menu
# or
./sipp-control.sh
```

Then:
1. Select "2. Run UAC Test"
2. Choose "sipp_uac_basic.xml"
3. Enter your SBC IP
4. Accept defaults (10 CPS, 100 calls)
5. Watch the test run!

### Option B: Command Line (Fastest)

```bash
# Basic connectivity test
./sipp-control.sh run-uac sipp_uac_basic.xml 192.168.1.100 10 100 1000

# Replace 192.168.1.100 with your SBC IP
```

### Option C: Docker Compose (Multi-Container)

```bash
# Edit .env first
export SBC_IP=192.168.1.100

# Start containers
make up-sbc

# Monitor
make status
make monitor
```

---

## 5. Monitor Your Tests

```bash
# Real-time dashboard (recommended)
make monitor

# Container status
make status

# View logs
make logs

# Statistics
cat logs/*-stats.csv
```

---

## Common Test Scenarios

### Basic Connectivity

```bash
./sipp-control.sh run-uac sipp_uac_basic.xml 192.168.1.100 1 10 100
```

### G.711 Audio Test

```bash
./sipp-control.sh run-uac sipp_uac_pcap_g711a.xml 192.168.1.100 10 100 1000
```

### Registration Load

```bash
./sipp-control.sh run-uac sipp_uac_register.xml 192.168.1.100 50 500
```

### Long Duration (17 minutes)

```bash
./sipp-control.sh run-uac 17minutes_G711.xml 192.168.1.100 5 50
```

### High Load Stress Test

```bash
./sipp-control.sh run-uac sipp_uac_basic.xml 192.168.1.100 100 1000 10000
```

---

## Useful Commands

```bash
# List all scenarios
./sipp-control.sh list-scenarios

# Check status
./sipp-control.sh status

# Stop all tests
./sipp-control.sh stop-all
make clean

# View help
make help
./sipp-control.sh help
```

---

## Troubleshooting

**Docker not installed?**
```bash
sudo ./scripts/setup-docker-el.sh
```

**Permission denied?**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Logout and login
```

**Can't reach SBC?**
```bash
# Test connectivity
ping <SBC_IP>
telnet <SBC_IP> 5060

# Check firewall
sudo firewall-cmd --list-all
```

**No RTP media?**
```bash
# Verify PCAP files
ls -lh scens/*.pcap

# Check ports
sudo netstat -an | grep 16384
```

---

## Next Steps

1. **Read Full Documentation**: [README.md](README.md)
2. **Browse Scenarios**: [scens/README.md](scens/README.md)
3. **Advanced Testing**: See README.md "Advanced Usage" section
4. **SBC Load Testing**: Use `docker-compose-sbc-test.yml`

---

## Quick Reference

| Task | Command |
|------|---------|
| Build | `make build` |
| Interactive menu | `make menu` |
| Run test | `./sipp-control.sh run-uac <scenario> <ip>` |
| Monitor | `make monitor` |
| Status | `make status` |
| Stop all | `make clean` |
| Help | `make help` |

---

## Support

- Full README: [README.md](README.md)
- Scenario catalog: [scens/README.md](scens/README.md)
- Issues: Report on GitHub

---

**Version**: 1.0.0
**Last Updated**: 2025-10-26
