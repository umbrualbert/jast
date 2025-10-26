FROM ubuntu:22.04
MAINTAINER Albert Etsebeth - umbrualbert@gmail.com

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for building SIPp with TLS/SSL support
RUN apt-get update && apt-get install -y \
    # Build tools
    build-essential \
    cmake \
    git \
    wget \
    pkg-config \
    # SIPp dependencies
    libncurses5-dev \
    libncursesw5-dev \
    libpcap-dev \
    libdnet-dev \
    # TLS/SSL support (OpenSSL >= 1.1.0)
    libssl-dev \
    openssl \
    # SCTP support
    libsctp-dev \
    lksctp-tools \
    # GSL (GNU Scientific Library) for advanced statistics
    libgsl-dev \
    # Utilities
    vim \
    tcpdump \
    net-tools \
    iproute2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set SIPp version (use latest stable release)
# Change this to "master" for bleeding edge, or specific tag like "v3.7.3"
ENV SIPP_VERSION=v3.7.3

# Clone and build SIPp with full feature support
RUN git clone --depth 1 --branch ${SIPP_VERSION} https://github.com/SIPp/sipp.git /tmp/sipp && \
    cd /tmp/sipp && \
    # Configure with CMake - enable all major features
    cmake . \
        -DUSE_SSL=1 \
        -DUSE_SCTP=1 \
        -DUSE_PCAP=1 \
        -DUSE_GSL=1 \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_BUILD_TYPE=Release && \
    # Build and install
    make -j$(nproc) && \
    make install && \
    # Verify installation
    sipp -v && \
    # Clean up build files
    cd / && \
    rm -rf /tmp/sipp

# Create directories for scenarios, logs, and SSL certificates
RUN mkdir -p /scens /logs /certs

# Copy scenarios
COPY scens/* /scens/

# Copy run script
COPY scripts/run_sipp.sh /run_sipp.sh
RUN chmod +x /run_sipp.sh

# Create a default self-signed certificate for TLS testing
# Users should mount their own certificates in production
RUN openssl req -new -x509 -days 3650 -nodes \
    -out /certs/sipp.crt \
    -keyout /certs/sipp.key \
    -subj "/C=US/ST=Test/L=Test/O=SIPp/OU=Testing/CN=sipp.local" && \
    chmod 600 /certs/sipp.key

# Set default SSL certificate paths
ENV SIPP_SSL_CERT=/certs/sipp.crt
ENV SIPP_SSL_KEY=/certs/sipp.key

# Expose ports
# SIP signaling (UDP/TCP/TLS)
EXPOSE 5060/udp
EXPOSE 5060/tcp
EXPOSE 5061/tcp
EXPOSE 5061/udp
EXPOSE 5060-5069/udp
EXPOSE 5060-5069/tcp

# SIPS (SIP over TLS) - standard port
EXPOSE 5061/tcp

# SIPp control/statistics
EXPOSE 8888/tcp
EXPOSE 8888/udp

# RTP media ports
EXPOSE 16384-32000/udp

# SCTP (if using SCTP transport)
EXPOSE 5060/sctp
EXPOSE 5061/sctp

# Volumes for persistence
VOLUME ["/logs", "/scens", "/certs"]

# Command to run SIPp
CMD ["/bin/bash", "/run_sipp.sh"]

# Labels
LABEL version="${SIPP_VERSION}" \
      description="SIPp ${SIPP_VERSION} with TLS/SSL, SCTP, PCAP, and GSL support" \
      maintainer="umbrualbert@gmail.com" \
      features="TLS,SSL,SCTP,PCAP,GSL" \
      base="ubuntu:22.04"

# Health check (optional - checks if sipp binary exists and is executable)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD sipp -v || exit 1
