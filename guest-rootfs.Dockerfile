FROM --platform=linux/riscv64 riscv64/ubuntu:22.04

# Update system
RUN apt-get update && apt-get upgrade -y

# Install busybox
RUN apt-get install -y busybox-static

# Install emulator tools
RUN <<EOF
apt-get install -y wget
wget -O machine-emulator-tools.deb https://github.com/cartesi/machine-emulator-tools/releases/download/v0.12.0/machine-emulator-tools-v0.12.0.deb
dpkg -i machine-emulator-tools.deb
rm -f machine-emulator-tools.deb
EOF

# Install debug tools
RUN apt-get install -y gdb strace device-tree-compiler

# Install testing tools
RUN apt-get install -y stress-ng

# Make build more or less reproducible
RUN rm -rf /var/lib/apt/lists/* /var/log/*

# Replace init
ADD --chmod=755 https://raw.githubusercontent.com/cartesi/machine-emulator-tools/09fb3f476c3155f876e1093836e1b56cac5dbd1d/skel/opt/cartesi/bin/init /opt/cartesi/bin/init
RUN echo guest-machine > /etc/hostname
