HOST_LINUX=linux-6.5.6-ctsi-y-v0.17.0.bin
GUEST_LINUX=linux-nobbl-6.5.6-ctsi-y-v0.17.0.bin

all: host-image guest-image
host-image: host-rootfs.ext2
guest-image: guest-rootfs.ext2

%.tar: %.Dockerfile $(GUEST_LINUX)
	docker build --platform=linux/riscv64 --file $< --output type=tar,dest=$@ --progress plain .

%.gnutar: %.tar
	bsdtar -cf $@ --format=gnutar @$<

%.ext2: %.gnutar
	genext2fs --faketime --block-size 4096 --volume-label $* --readjustment +8k --tarball $< $@

clean:
	rm -f *.ext2 *.tar *.gnutar

CEMU=cartesi-machine
QEMU=qemu-system-riscv64

HOST_EMU=cemu
GUEST_EMU=lkvm

HOST_MEM=1024M
GUEST_MEM=256M

HOST_INIT=uname -a && \
busybox tunctl -t tap0 >/dev/null && \
busybox ip link set tap0 up && \
busybox ip addr add 192.168.3.1/24 dev tap0
GUEST_INIT=uname -a && \
busybox ip link set dev eth0 up && \
busybox ip addr add 192.168.3.2/24 dev eth0

HOST_CMD=bash
GUEST_CMD=bash

ifeq ($(HOST_EMU), cemu)
GUEST_ROOTFS_DEV=/dev/pmem1
else ifeq ($(HOST_EMU), qemu)
GUEST_ROOTFS_DEV=/dev/vdb
endif

ifeq ($(HOST_EMU), cemu)
host-run:
	$(CEMU) \
		--ram-length=$(HOST_MEM)i \
		--ram-image=$(HOST_LINUX) \
		--flash-drive=label:root,filename:host-rootfs.ext2 \
		--flash-drive=label:guest-root,filename:guest-rootfs.ext2,mount:false \
		--append-init="$(HOST_INIT)" \
		--no-init-splash \
		--quiet \
		-it -- "$(HOST_CMD)"
else ifeq ($(HOST_EMU), qemu)
host-run:
	$(QEMU) \
		-machine virt \
		-m $(HOST_MEM) -smp 1 \
		-cpu rv64,priv_spec=v1.12.0,zicbom=false,zicboz=false,zba=false,zbb=false,zbs=false,sstc=false,Zihintpause=false \
		-monitor none \
		-nographic \
		-snapshot \
		-drive file=host-rootfs.ext2,id=hd0,format=raw -device virtio-blk-device,drive=hd0 \
		-drive file=guest-rootfs.ext2,id=hd1,format=raw -device virtio-blk-device,drive=hd1 \
		-kernel $(GUEST_LINUX) \
		-append "quiet earlycon=sbi console=hvc0 rootfstype=ext2 root=/dev/vda rw init=/opt/cartesi/bin/init \
		-- \"$(HOST_INIT) && $(HOST_CMD)\""
endif

ifeq ($(GUEST_EMU), qemu)
guest-run:
	@$(MAKE) --no-print-directory host-run HOST_CMD="\
	qemu-system-riscv64 \
		-machine virt \
		-m $(GUEST_MEM) \
		-smp 1 \
		-monitor none \
		-serial null \
		-nographic \
		-snapshot \
		-bios none -enable-kvm \
		-device virtio-serial-device -chardev stdio,id=charcon0 -device virtconsole,chardev=charcon0 \
		-device virtio-net-device,netdev=net0 -netdev tap,ifname=tap0,id=net0,script=no,downscript=no \
		-device virtio-blk-device,drive=hd0 -drive file=$(GUEST_ROOTFS_DEV),id=hd0,format=raw \
		-kernel $(GUEST_LINUX) \
		-append 'quiet earlycon=sbi console=hvc1 rw rootfstype=ext2 root=/dev/vda init=/opt/cartesi/bin/init \
		-- $(GUEST_INIT) && $(GUEST_CMD)'"
else ifeq ($(GUEST_EMU), lkvm)
guest-run:
	@$(MAKE) --no-print-directory host-run HOST_CMD="\
	lkvm run \
		--loglevel warning \
		--mem $(GUEST_MEM) \
		--cpus 1 \
		--virtio-transport mmio \
		--balloon \
		--rng \
		--console hv \
		--network mode=tap,tapif=tap0 \
		--disk $(GUEST_ROOTFS_DEV) \
		--kernel $(GUEST_LINUX) \
		--params 'quiet earlycon=sbi console=hvc0 rw rootfstype=ext2 root=/dev/vda init=/opt/cartesi/bin/init \
		-- $(GUEST_INIT) && $(GUEST_CMD)'"
endif

guest-ping-test:
	@$(MAKE) --no-print-directory guest-run GUEST_CMD="busybox ping -c 1 192.168.3.1"

guest-stress-test:
	@$(MAKE) --no-print-directory guest-run GUEST_CMD="stress-ng \
		--class cpu,cpu-cache,memory,vm \
		--sequential 2 \
		--timeout 10s \
		--times \
		--verbose \
		--verify \
		--vm-bytes 64M"
