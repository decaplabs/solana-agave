# Multi-stage build for Solana test validator from source
# Note: We use the latest Rust image, then let rustup use the version
# specified in the repo's rust-toolchain.toml file
FROM rust:slim-bookworm AS builder

# Install build dependencies including STATIC libclang libraries
# We'll force static linking to avoid the dynamic library discovery issues
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    libudev-dev \
    clang \
    libclang-dev \
    llvm-dev \
    cmake \
    git \
    && rm -rf /var/lib/apt/lists/*

# Check for STATIC libclang libraries and llvm-config
RUN ldconfig && \
    echo "=== Checking for static libclang ===" && \
    find /usr/lib -name "libclang*.a" 2>/dev/null | head -10 || true && \
    echo "=== Checking for llvm-config ===" && \
    which llvm-config-14 || which llvm-config || echo "llvm-config not found" && \
    if [ -f /usr/bin/llvm-config-14 ]; then llvm-config-14 --libdir; fi && \
    echo "=== Installed clang/llvm packages ===" && \
    dpkg -l | grep -E "(clang|llvm)" && \
    echo "=== Clang version ===" && \
    clang --version

# Force STATIC linking of libclang instead of dynamic
# This avoids the LIBCLANG_PATH discovery issues entirely
ENV LIBCLANG_STATIC=1
ENV LLVM_CONFIG_PATH=/usr/bin/llvm-config-14
ENV BINDGEN_EXTRA_CLANG_ARGS="-I/usr/include"

# Verify llvm-config exists
RUN which llvm-config-14 || which llvm-config || echo "WARNING: llvm-config not found"

# Set working directory
WORKDIR /solana

# Copy the Solana repository (assumes you're building from repo root)
COPY . .

# Create .cargo/config.toml to force STATIC linking of libclang
# This avoids all the dynamic library path issues
RUN mkdir -p .cargo && \
    echo '[env]' > .cargo/config.toml && \
    echo 'LIBCLANG_STATIC = { value = "1", force = true }' >> .cargo/config.toml && \
    echo 'LLVM_CONFIG_PATH = { value = "/usr/bin/llvm-config-14", force = true }' >> .cargo/config.toml && \
    echo 'BINDGEN_EXTRA_CLANG_ARGS = { value = "-I/usr/include", force = true }' >> .cargo/config.toml

RUN cat .cargo/config.toml

# Install the Rust toolchain version specified in rust-toolchain.toml
# This ensures we use the exact version required by this Solana version
RUN rustup show

# Build solana-test-validator and required binaries
# Using STATIC linking for libclang to avoid path discovery issues
RUN set -x && \
    echo "=== Verifying .cargo/config.toml ===" && \
    cat .cargo/config.toml && \
    echo "=== Setting static linking environment ===" && \
    export LIBCLANG_STATIC=1 && \
    export LLVM_CONFIG_PATH=/usr/bin/llvm-config-14 && \
    export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/include" && \
    echo "LIBCLANG_STATIC=$LIBCLANG_STATIC" && \
    echo "LLVM_CONFIG_PATH=$LLVM_CONFIG_PATH" && \
    echo "=== Starting cargo build with static libclang ===" && \
    cargo build --release --bin solana-test-validator --bin solana-faucet

# Runtime stage - smaller image
FROM ubuntu:22.04

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled binaries from builder
COPY --from=builder /solana/target/release/solana-test-validator /usr/local/bin/
COPY --from=builder /solana/target/release/solana-faucet /usr/local/bin/

# Create ledger directory
RUN mkdir -p /solana/ledger

# Create a non-root user (optional but recommended)
RUN useradd -m -u 1000 solana && \
    chown -R solana:solana /solana

USER solana
WORKDIR /solana

# Expose RPC, WebSocket, and Faucet ports
EXPOSE 8899 8900 9900

# Run solana-test-validator
CMD ["solana-test-validator", \
     "--ledger", "/solana/ledger", \
     "--rpc-port", "8899", \
     "--faucet-port", "9900", \
     "--log"]