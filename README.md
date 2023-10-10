# Hypervisor playground

Experiments with Cartesi Machine, QEMU and RISC-V Hypervisor extension.

Make sure you have QEMU >= 8.1+, and latest Cartesi Machine.

## Compile rootfs

Make sure you have Docker with RISC-V 64 support and our patched genext2fs available first.

```bash
# Compile host rootfs and guest rootfs
make all
```

## Host Shell

Host shell for running guest machines manually.

```shell
# Cartesi Machine as host emulator
make host-run HOST_EMU=cemu
# QEMU as host emulator
make host-run HOST_EMU=qemu
```

## Guest Shell

Guest shell for testing a guest machine.

```shell
# Cartesi Machine as host emulator, LKVM as guest emulator
make guest-run HOST_EMU=cemu GUEST_EMU=lkvm
# Cartesi Machine as host emulator, QEMU as guest emulator
make guest-run HOST_EMU=cemu GUEST_EMU=qemu
# QEMU as host emulator, LKVM as guest emulator
make guest-run HOST_EMU=qemu GUEST_EMU=lkvm
# QEMU as host emulator, QEMU as guest emulator
make guest-run HOST_EMU=qemu GUEST_EMU=qemu
```

By default `HOST_EMU` is `cemu` and `GUEST_EMU` is `lkvm`.

## Guest Commands

You can test guest commands by setting GUEST_CMD:

```shell
# Cartesi Machine as host emulator, LKVM as guest emulator
make guest-run HOST_EMU=cemu GUEST_EMU=lkvm GUEST_CMD="echo HELLO FROM GUEST"
# Cartesi Machine as host emulator, QEMU as guest emulator
make guest-run HOST_EMU=cemu GUEST_EMU=qemu GUEST_CMD="echo HELLO FROM GUEST"
# QEMU as host emulator, LKVM as guest emulator
make guest-run HOST_EMU=qemu GUEST_EMU=lkvm GUEST_CMD="echo HELLO FROM GUEST"
# QEMU as host emulator, QEMU as guest emulator
make guest-run HOST_EMU=qemu GUEST_EMU=qemu GUEST_CMD="echo HELLO FROM GUEST"
```

## Tests

```bash
# ping host machine test
make guest-ping-test
# intensive stress tests (should take hours)
make guest-stress-test
```

You can use the same `HOST_EMU` and `GUEST_EMU` options.

References for interesting stress tests with stress-ng:
- https://wiki.ubuntu.com/Kernel/Reference/stress-ng
