FROM --platform=linux/riscv64 riscv64/ubuntu:22.04

RUN <<EOF
# Update system
apt-get update && apt-get upgrade -y

# Install busybox
apt-get install -y busybox-static

# Install debug tools
apt-get install -y gdb strace device-tree-compiler

# Install testing tools
apt-get install -y stress-ng

# Install socat (for testing VSOCKETS)
apt-get install -y socat

# Make build more or less reproducible
rm -rf /var/lib/apt/lists/* /var/log/*
EOF

# Install emulator tools
ADD https://github.com/cartesi/machine-emulator-tools/releases/download/v0.13.0/machine-emulator-tools-v0.13.0.deb machine-emulator-tools.deb
RUN <<EOF
dpkg -i machine-emulator-tools.deb
rm -f machine-emulator-tools.deb
EOF

# Replace machine name
RUN echo guest-machine > /etc/hostname
