# SIPp TLS/SIPS Testing Guide

Complete guide for using TLS/SIPS (SIP over TLS) with the JAST testing framework.

---

## Table of Contents

- [Overview](#overview)
- [TLS Support](#tls-support)
- [Certificates](#certificates)
- [TLS Scenarios](#tls-scenarios)
- [Usage Examples](#usage-examples)
- [Docker Configuration](#docker-configuration)
- [Troubleshooting](#troubleshooting)

---

## Overview

**What's New in SIPp 3.7.3:**
- ✅ Full TLS/SSL support (OpenSSL 1.1.0+)
- ✅ SIPS (SIP over TLS) on port 5061
- ✅ TLS key logging for Wireshark decryption
- ✅ SCTP transport support
- ✅ Enhanced statistics with GSL

**Security Features:**
- Encrypted SIP signaling
- Certificate-based authentication
- Perfect Forward Secrecy (PFS) support
- TLS 1.2 and TLS 1.3 support

---

## TLS Support

### Build Configuration

The Docker image is built with full TLS support:

```dockerfile
cmake . \
    -DUSE_SSL=1       # Enable TLS/SSL
    -DUSE_SCTP=1      # Enable SCTP
    -DUSE_PCAP=1      # Enable PCAP playback
    -DUSE_GSL=1       # Enable advanced statistics
```

### Verify TLS Support

```bash
# Check SIPp version and features
docker run --rm sipp:3.7.3 sipp -v

# Should show:
# SIPp v3.7.3 with OpenSSL, PCAP, SCTP, GSL support
```

---

## Certificates

### Default Self-Signed Certificates

The Docker image includes default self-signed certificates:

**Location:**
- Certificate: `/certs/sipp.crt`
- Private Key: `/certs/sipp.key`

**Details:**
- Valid for 10 years
- Common Name: `sipp.local`
- Organization: `SIPp Testing`

### Using Your Own Certificates

#### Method 1: Mount Certificates Volume

```bash
# Place your certificates in ./certs directory
mkdir -p ./certs
cp your-cert.crt ./certs/
cp your-key.key ./certs/

# Docker will mount them automatically
docker compose up -d
```

#### Method 2: Specify in Docker Run

```bash
docker run -d \
  -v /path/to/your/certs:/certs:ro \
  -e ARGS="-t l1 -tls_cert /certs/your-cert.crt -tls_key /certs/your-key.key \
           -sf /scens/tls/sipp_uac_tls_basic.xml <target>:5061" \
  sipp:3.7.3
```

### Generate Custom Certificates

**For Testing (Self-Signed):**

```bash
cd certs/

# Generate private key
openssl genrsa -out sipp-test.key 2048

# Generate certificate (valid 365 days)
openssl req -new -x509 -key sipp-test.key -out sipp-test.crt -days 365 \
  -subj "/C=US/ST=Test/L=Test/O=YourOrg/OU=Testing/CN=sipp.yourdomain.com"

# Verify certificate
openssl x509 -in sipp-test.crt -text -noout
```

**For Production (CA-Signed):**

```bash
# Generate CSR
openssl req -new -key sipp.key -out sipp.csr \
  -subj "/C=US/ST=State/L=City/O=YourOrg/OU=VoIP/CN=sipp.yourdomain.com"

# Send sipp.csr to your CA
# Receive signed certificate as sipp.crt
```

---

## TLS Scenarios

### Available TLS Scenarios

Located in `scens/tls/`:

1. **`sipp_uac_tls_basic.xml`** - Basic SIPS UAC (client)
   - TLS transport
   - Simple INVITE/200/ACK/BYE
   - Encrypted signaling

2. **`sipp_uas_tls_basic.xml`** - Basic SIPS UAS (server)
   - TLS listener
   - Auto-answer with 180/200
   - Encrypted signaling

### TLS Scenario Features

**Transport Type:**
- Uses `sips:` URI scheme instead of `sip:`
- Via header: `SIP/2.0/TLS` instead of `SIP/2.0/UDP`
- Contact header: `sips:` instead of `sip:`

**Default Port:**
- Standard SIPS port: **5061** (instead of 5060)

---

## Usage Examples

### 1. Basic TLS UAC Test

```bash
# Using control script
./sipp-control.sh run-uac-tls sipp_uac_tls_basic.xml 192.168.1.100

# Direct Docker command
docker run --rm \
  --network host \
  -v $(pwd)/scens:/scens:ro \
  -v $(pwd)/certs:/certs:ro \
  sipp:3.7.3 \
  sipp -t l1 \
       -tls_cert /certs/sipp.crt \
       -tls_key /certs/sipp.key \
       -sf /scens/tls/sipp_uac_tls_basic.xml \
       -r 10 -m 100 \
       192.168.1.100:5061
```

### 2. TLS UAS Server

```bash
# Start TLS server on port 5061
docker run --rm \
  --network host \
  -v $(pwd)/scens:/scens:ro \
  -v $(pwd)/certs:/certs:ro \
  sipp:3.7.3 \
  sipp -t l1 \
       -tls_cert /certs/sipp.crt \
       -tls_key /certs/sipp.key \
       -sf /scens/tls/sipp_uas_tls_basic.xml \
       -p 5061
```

### 3. TLS Load Testing

```bash
# High CPS TLS test
docker run --rm \
  --network host \
  -v $(pwd)/scens:/scens:ro \
  -v $(pwd)/certs:/certs:ro \
  sipp:3.7.3 \
  sipp -t l1 \
       -tls_cert /certs/sipp.crt \
       -tls_key /certs/sipp.key \
       -sf /scens/tls/sipp_uac_tls_basic.xml \
       -r 100 -m 1000 -l 10000 \
       192.168.1.100:5061
```

### 4. TLS with Custom Certificates

```bash
docker run --rm \
  --network host \
  -v $(pwd)/scens:/scens:ro \
  -v /etc/ssl/mycompany:/certs:ro \
  sipp:3.7.3 \
  sipp -t l1 \
       -tls_cert /certs/production.crt \
       -tls_key /certs/production.key \
       -sf /scens/tls/sipp_uac_tls_basic.xml \
       -r 50 -m 500 \
       production-sbc.example.com:5061
```

### 5. TLS with Key Logging (Wireshark Decryption)

```bash
# Enable TLS key logging for debugging
docker run --rm \
  --network host \
  -v $(pwd)/scens:/scens:ro \
  -v $(pwd)/certs:/certs:ro \
  -v $(pwd)/logs:/logs \
  -e SSLKEYLOGFILE=/logs/sipp-tls-keys.log \
  sipp:3.7.3 \
  sipp -t l1 \
       -tls_cert /certs/sipp.crt \
       -tls_key /certs/sipp.key \
       -sf /scens/tls/sipp_uac_tls_basic.xml \
       192.168.1.100:5061

# Use logs/sipp-tls-keys.log in Wireshark:
# Edit -> Preferences -> Protocols -> TLS -> (Pre)-Master-Secret log filename
```

---

## Docker Configuration

### Docker Compose with TLS

**File: `docker-compose-tls.yml`**

```yaml
version: '3.8'

services:
  uac-tls:
    image: sipp:3.7.3
    container_name: sipp-uac-tls
    network_mode: host
    environment:
      ARGS: >-
        -t l1
        -tls_cert /certs/sipp.crt
        -tls_key /certs/sipp.key
        -sf /scens/tls/sipp_uac_tls_basic.xml
        -r 10 -m 100
        ${SBC_IP}:5061
    volumes:
      - ./scens:/scens:ro
      - ./certs:/certs:ro
      - ./logs:/logs
      - ./scripts/run_sipp.sh:/run_sipp.sh:ro

  uas-tls:
    image: sipp:3.7.3
    container_name: sipp-uas-tls
    network_mode: host
    environment:
      ARGS: >-
        -t l1
        -tls_cert /certs/sipp.crt
        -tls_key /certs/sipp.key
        -sf /scens/tls/sipp_uas_tls_basic.xml
        -p 5061
    volumes:
      - ./scens:/scens:ro
      - ./certs:/certs:ro
      - ./logs:/logs
      - ./scripts/run_sipp.sh:/run_sipp.sh:ro
```

**Usage:**
```bash
export SBC_IP=192.168.1.100
docker compose -f docker-compose-tls.yml up -d
```

### Environment Variables

```bash
# .env file
SBC_IP=192.168.1.100
SBC_TLS_PORT=5061
TLS_CERT_PATH=./certs/production.crt
TLS_KEY_PATH=./certs/production.key
```

---

## TLS Command-Line Parameters

### Essential TLS Flags

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-t l1` | Use TLS transport (layer 1) | `-t l1` |
| `-tls_cert <file>` | Path to TLS certificate | `-tls_cert /certs/sipp.crt` |
| `-tls_key <file>` | Path to TLS private key | `-tls_key /certs/sipp.key` |
| `-tls_crl <file>` | Certificate Revocation List | `-tls_crl /certs/crl.pem` |
| `-tls_version <ver>` | TLS version (1.0, 1.1, 1.2, 1.3) | `-tls_version 1.2` |

### Advanced TLS Options

| Parameter | Description |
|-----------|-------------|
| `-tls_skip_verification` | Skip certificate verification (insecure!) |
| `-DUSE_SSL=KL` | Enable TLS key logging (build-time) |

---

## SBC TLS Testing

### Testing TLS Termination

```bash
# Test SBC as TLS server (UAC uses TLS)
./sipp-control.sh run-uac-tls sipp_uac_tls_basic.xml <SBC_IP> 50 500

# Monitor with tcpdump (encrypted traffic)
sudo tcpdump -i any -s0 -w tls-test.pcap port 5061
```

### Testing TLS Passthrough

```bash
# UAC -> SBC (TLS) -> UAS (TLS)
# Start UAS on backend
docker run -d --name uas-tls \
  --network host \
  -v $(pwd)/scens:/scens:ro \
  -v $(pwd)/certs:/certs:ro \
  sipp:3.7.3 \
  sipp -t l1 -tls_cert /certs/sipp.crt -tls_key /certs/sipp.key \
       -sf /scens/tls/sipp_uas_tls_basic.xml -p 5062

# Start UAC pointing to SBC
./sipp-control.sh run-uac-tls sipp_uac_tls_basic.xml <SBC_IP> 10 100
```

### Testing Mixed Transport

```bash
# UAC (TLS) -> SBC -> UAS (UDP)
# SBC performs TLS termination and protocol conversion

# Start UAS on UDP
docker run -d --name uas-udp \
  --network host \
  -v $(pwd)/scens:/scens:ro \
  sipp:3.7.3 \
  sipp -sf /scens/sipp_uas_basic.xml -p 5060

# Start UAC on TLS
./sipp-control.sh run-uac-tls sipp_uac_tls_basic.xml <SBC_IP> 10 100
```

---

## Troubleshooting

### Certificate Errors

**Error:** `TLS handshake failed`

```bash
# Check certificate validity
openssl x509 -in /certs/sipp.crt -text -noout | grep -A2 Validity

# Check certificate matches key
openssl x509 -noout -modulus -in /certs/sipp.crt | openssl md5
openssl rsa -noout -modulus -in /certs/sipp.key | openssl md5
# MD5 hashes must match
```

**Error:** `Certificate verify failed`

```bash
# Option 1: Use valid CA-signed certificate
# Option 2: Skip verification (testing only!)
sipp -t l1 -tls_skip_verification ...
```

### Connection Issues

**Error:** `Connection refused on port 5061`

```bash
# Check if port is open
netstat -an | grep 5061

# Check firewall
sudo firewall-cmd --list-ports

# Add port if needed
sudo firewall-cmd --permanent --add-port=5061/tcp
sudo firewall-cmd --reload
```

**Error:** `TLS version mismatch`

```bash
# Force specific TLS version
sipp -t l1 -tls_version 1.2 ...

# Check server supported versions
openssl s_client -connect <SBC_IP>:5061 -tls1_2
```

### Performance Issues

TLS is more CPU-intensive than UDP:

```bash
# Reduce load for TLS testing
# Instead of: -r 200 -m 2000
# Try:        -r 100 -m 1000

# Monitor CPU
docker stats sipp-uac-tls
```

### Debugging TLS

**Capture and decrypt:**

```bash
# 1. Run SIPp with key logging
SSLKEYLOGFILE=/logs/keys.log sipp -t l1 ...

# 2. Capture traffic
sudo tcpdump -i any -s0 -w tls-debug.pcap port 5061

# 3. Open in Wireshark
# Edit -> Preferences -> Protocols -> TLS -> (Pre)-Master-Secret log filename
# Browse to /logs/keys.log
```

**Verbose TLS output:**

```bash
# Enable SIPp message tracing
sipp -t l1 -trace_msg -trace_err ...
```

---

## Performance Considerations

### TLS vs UDP Performance

| Metric | UDP | TLS | Impact |
|--------|-----|-----|--------|
| CPU Usage | Low | High | 2-3x more CPU |
| Call Setup Time | ~10ms | ~50ms | Handshake overhead |
| Max CPS | 500+ | 200+ | Encryption overhead |
| Memory | Low | Medium | Session state |

### Recommendations

1. **CPU Allocation**: Allocate more CPU for TLS containers
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '4.0'  # Instead of 2.0 for UDP
   ```

2. **CPS Limits**: Reduce call rate expectations
   - UDP: 200+ CPS achievable
   - TLS: 50-100 CPS realistic

3. **Connection Reuse**: TLS connections can be reused
   - Reduces handshake overhead
   - Better performance for sustained load

---

## Security Best Practices

### Production Deployment

1. **Use Valid Certificates**:
   - CA-signed certificates
   - Proper CN/SAN for your domain
   - Regular renewal before expiry

2. **Strong Ciphers**:
   ```bash
   # Configure OpenSSL cipher suites
   export OPENSSL_CONF=/etc/ssl/openssl-strong.cnf
   ```

3. **TLS Version**:
   - Minimum TLS 1.2
   - Prefer TLS 1.3 if supported
   ```bash
   sipp -t l1 -tls_version 1.3 ...
   ```

4. **Certificate Validation**:
   - Always validate in production
   - Never use `-tls_skip_verification` in production

5. **Key Protection**:
   ```bash
   # Protect private keys
   chmod 600 /certs/sipp.key
   chown root:root /certs/sipp.key
   ```

---

## Additional Resources

- **SIPp TLS Documentation**: https://sipp.readthedocs.io/en/latest/
- **OpenSSL Manual**: https://www.openssl.org/docs/
- **RFC 3261 (SIP)**: https://www.rfc-editor.org/rfc/rfc3261
- **RFC 5246 (TLS 1.2)**: https://www.rfc-editor.org/rfc/rfc5246
- **RFC 8446 (TLS 1.3)**: https://www.rfc-editor.org/rfc/rfc8446

---

## Quick Reference

```bash
# Build TLS-enabled image
make build

# Run TLS UAC
docker run --rm --network host \
  -v $(pwd)/scens:/scens:ro \
  -v $(pwd)/certs:/certs:ro \
  sipp:3.7.3 \
  sipp -t l1 -tls_cert /certs/sipp.crt -tls_key /certs/sipp.key \
       -sf /scens/tls/sipp_uac_tls_basic.xml -r 10 -m 100 <IP>:5061

# Run TLS UAS
docker run --rm --network host \
  -v $(pwd)/scens:/scens:ro \
  -v $(pwd)/certs:/certs:ro \
  sipp:3.7.3 \
  sipp -t l1 -tls_cert /certs/sipp.crt -tls_key /certs/sipp.key \
       -sf /scens/tls/sipp_uas_tls_basic.xml -p 5061

# Verify TLS support
docker run --rm sipp:3.7.3 sipp -v

# Generate test certificate
openssl req -new -x509 -days 365 -nodes \
  -out certs/test.crt -keyout certs/test.key \
  -subj "/CN=sipp.test.local"
```

---

**Version**: 1.0.0
**Last Updated**: 2025-10-26
**SIPp Version**: 3.7.3
**OpenSSL**: 1.1.0+
