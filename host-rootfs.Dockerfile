FROM --platform=linux/riscv64 busybox:latest AS busybox-stage
FROM --platform=linux/riscv64 riscv64/alpine:edge

RUN <<EOF
# Update system
apk update && apk upgrade

# Install busybox
apk add busybox

# Install debug tools
apk add gdb strace dtc bash tmux

# Install qemu
apk add qemu qemu-riscv64 qemu-system-riscv64

# Install build essential
apk add gcc git make

# Install development headers and libraries
apk add libc-dev linux-headers libfdt

# Install socat (for testing VSOCKETS)
apk add socat

# Install stress testing tools
apk add stress-ng

# Make build more or less reproducible
rm -rf /var/lib/apt/lists/* /var/log/*
EOF

# Replace busybox with cttyhack syupport
COPY --from=busybox-stage /bin/busybox /bin/busybox

# Install kvmtool
ADD https://raw.githubusercontent.com/ziglang/zig/5f864140194c91a60cb8e132a7596b555971e808/lib/libc/include/riscv64-linux-gnu/bits/wordsize.h /usr/include/bits/wordsize.h
RUN <<EOF
git clone https://github.com/edubart/kvmtool.git
cd kvmtool
make lkvm-static -j4
install lkvm-static /usr/bin/lkvm
EOF

# Replace init
ADD --chmod=755 https://raw.githubusercontent.com/cartesi/machine-emulator-tools/v0.13.0/skel/opt/cartesi/bin/init /opt/cartesi/bin/init

# Replace machine name
RUN echo host-machine > /etc/hostname

# Copy guest linux
COPY linux-nobbl-6.5.9-ctsi-y-v0.18.0.bin /root
