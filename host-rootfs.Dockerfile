FROM --platform=linux/riscv64 busybox:latest AS busybox-stage
FROM --platform=linux/riscv64 riscv64/alpine:edge

# Update system
RUN apk update && apk upgrade

# Install busybox with cttyhack support
RUN apk add busybox
COPY --from=busybox-stage /bin/busybox /bin/busybox

# Install debug tools
RUN apk add gdb strace dtc bash tmux

# Install qemu
RUN apk add qemu qemu-riscv64 qemu-system-riscv64

# Install testing tools
RUN apk add stress-ng

# Install build essential
RUN apk add gcc git make

# Install development headers and libraries
RUN apk add libc-dev linux-headers libfdt

# Install kvmtool
RUN <<EOF
git clone https://github.com/edubart/kvmtool.git
cd kvmtool
make lkvm-static -j4
install lkvm-static /usr/bin/lkvm
EOF

# Make build more or less reproducible
RUN rm -rf /var/lib/apt/lists/* /var/log/*

# Replace init
ADD --chmod=755 https://raw.githubusercontent.com/cartesi/machine-emulator-tools/09fb3f476c3155f876e1093836e1b56cac5dbd1d/skel/opt/cartesi/bin/init /opt/cartesi/bin/init
RUN echo host-machine > /etc/hostname

# Copy guest linux
COPY linux-nobbl-6.5.6-ctsi-y-v0.17.0.bin /root
