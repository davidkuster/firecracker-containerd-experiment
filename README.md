# firecracker-containerd-experiment

## Objective

Use FirecrackerVM / firecracker-containerd as an isolation wrapper around Docker containers.


## Experiment notes

Running both Ubuntu 22.04 (Jammy Jellyfish) from a live USB disk and Debian 12 (bookworm) in VirtualBox on a Mac (and then a live USB as well). Initially started with Ubuntu because I'm more familiar with it but the [firecracker-containerd quickstart](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/quickstart.md) is Debian-oriented so I may be swimming against the tide with Ubuntu.

<!-- MarkdownTOC autolink="true" -->

- [Debian 12 \(live USB\) - skip build](#debian-12-live-usb---skip-build)
- [Debian 11 \(live USB\)](#debian-11-live-usb)
- [Debian 12 \(live USB\)](#debian-12-live-usb)
- [Debian \(in VirtualBox\)](#debian-in-virtualbox)
- [Random](#random)
    - [DNS](#dns)
    - [Logs](#logs)
- [Ubuntu \(live USB\)](#ubuntu-live-usb)
- [References](#references)

<!-- /MarkdownTOC -->

### Debian 12 (live USB) - skip build

1. `sudo apt update`
1. `git clone https://github.com/davidkuster/firecracker-containerd-experiment`
1. `./scripts/debian/fc-setup.sh` 
1. `./scripts/debian/fc-install-skip-build.sh`
1. `sudo firecracker-containerd --config /etc/firecracker-containerd/config.toml`
1. Open new tab, then `su - $(whoami)` and `groups` - ensure `docker` is in the list 
1. In new tab:
    ```bash
    sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock \
    image pull \
    --snapshotter devmapper \
    docker.io/library/debian:latest
    ```
1. Again in new tab:
    ```bash
    sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock \
    run \
    --snapshotter devmapper \
    --runtime aws.firecracker \
    --rm --tty --net-host \
    docker.io/library/debian:latest \
    test
    ```
1. In the logs of the first tab where `firecracker-containerd` is running, it has these errors:
    ```bash
    DEBU[2024-07-17T03:40:30.735327018Z]                                               attempt=194 error="temporary vsock dial failure: vsock ack message failure: failed to read \"OK <port>\" within 1s: EOF" runtime=aws.firecracker vmID=3b1c16eb-9dc6-46ac-903c-7db5107d8b2c
    DEBU[2024-07-17T03:40:30.805937712Z] sending signal 9 to 6793                      jailer=noop runtime=aws.firecracker vmID=3b1c16eb-9dc6-46ac-903c-7db5107d8b2c
    ERRO[2024-07-17T03:40:30.806149695Z] failed to create VM                           error="failed to dial the VM over vsock: context deadline exceeded" runtime=aws.firecracker vmID=3b1c16eb-9dc6-46ac-903c-7db5107d8b2c
    DEBU[2024-07-17T03:40:30.806665716Z] stopVMM(): sending sigterm to firecracker     runtime=aws.firecracker
    ERRO[2024-07-17T03:40:30.807201288Z] shim CreateVM returned error                  error="rpc error: code = DeadlineExceeded desc = VM \"3b1c16eb-9dc6-46ac-903c-7db5107d8b2c\" didn't start within 20s: failed to dial the VM over vsock: context deadline exceeded"
    ERRO[2024-07-17T03:40:30.810482731Z] copy shim log                                 error="read /proc/self/fd/12: file already closed" namespace=default
    DEBU[2024-07-17T03:40:30.810779988Z] shim has been terminated                      error="signal: killed" vmID=3b1c16eb-9dc6-46ac-903c-7db5107d8b2c
    ```
1. See full log output in [logs/fc.log](logs/fc.log) (running above command with `> logs/fc.log 2>&1`)   

### Debian 11 (live USB)

Starting fresh from a Debian 11 (bullseye) live USB.

> Note wifi does not work by default with Debian 11. I dug out a network cable.

1. `sudo apt update`
2. `sudo apt install git`
3. `git clone https://github.com/davidkuster/firecracker-containerd-experiment`
4. `scripts/debian/fc-setup.sh` ([source](scripts/debian/fc-setup.sh))
5. `sudo scripts/debian/fc-install.sh` ([source](scripts/debian/fc-install.sh))
6. Wait for it to run out of disk space, then run `sudo scripts/docker-fix-disk-space.sh` ([source](scripts/docker-fix-disk-space.sh))
7. Rerun `sudo scripts/debian/fc-install.sh`
    - same error
        ```bash
        docker run --rm \
        	--security-opt=apparmor=unconfined \
        	--volume /home/user/firecracker-containerd/tools/image-builder:/src \
        	--volume /src/tmp \
        	--cap-add=sys_admin \
        	--cap-add=sys_chroot \
        	--env=DEBMIRROR \
	        fc-image-builder:latest all
        mkdir tmp/rootfs
        debootstrap --variant=minbase --include=udev,systemd,systemd-sysv,procps,libseccomp2,haveged bullseye "tmp/rootfs" http://deb.debian.org/debian
        /usr/sbin/debootstrap: 1723: cannot create /src/tmp/rootfs/test-dev-null: Permission denied
        E: Cannot install into target '/src/tmp/rootfs' mounted with noexec or nodev
        make: *** [Makefile:81: debootstrap_stamp] Error 1
        make[1]: *** [Makefile:119: all-in-docker] Error 2
        make[1]: Leaving directory '/root/firecracker-containerd/tools/image-builder'
        make: *** [Makefile:166: image] Error 2
        ```

### Debian 12 (live USB)

Starting fresh from a Debian 12 (bookworm) live USB.

1. `sudo apt-get update`
1. Clone this repo (git is already installed)
    1. `git clone https://github.com/davidkuster/firecracker-containerd-experiment`
1. Follow the firecracker-containerd [getting started](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/getting-started.md) instructions, included in this repo as slightly tweaked scripts:
    1. `scripts/debian/fc-setup.sh` ([source](scripts/debian/fc-setup.sh))
    1. `scripts/docker-fix-disk-space.sh` ([source](scripts/docker-fix-disk-space.sh)) (preemptively fix Docker disk space issues)
    1. `sudo scripts/debian/fc-install.sh` ([source](scripts/debian/fc-install.sh))
        - note the `sudo` here so that the Docker commands will work
        - current status
            - [this command](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/tools/image-builder/Makefile#L46-L55) in the `tools/image-builder/Makefile` returns an error:
            ```bash
            debootstrap --variant=minbase --include=udev,systemd,systemd-sysv,procps,libseccomp2,haveged bullseye "tmp/rootfs" http://deb.debian.org/debian
            /usr/sbin/debootstrap: 1723: cannot create /src/tmp/rootfs/test-dev-null: Permission denied
            E: Cannot install into target '/src/tmp/rootfs' mounted with noexec or nodev
            make: *** [Makefile:81: debootstrap_stamp] Error 1
            make[1]: *** [Makefile:119: all-in-docker] Error 2
            make[1]: Leaving directory '/root/firecracker-containerd/tools/image-builder'
            make: *** [Makefile:166: image] Error 2
            ```

> Note: this is the same error as in the Ubuntu attempt [below](#ubuntu-live-usb).


### Debian (in VirtualBox)

> TL;DR - this isn't working for me, due to virtualization issues. VirtualBox [doc](https://docs.oracle.com/en/virtualization/virtualbox/7.0/user/AdvancedTopics.html) indicates this should work:
>> Oracle VM VirtualBox supports nested virtualization. This feature enables the passthrough of hardware virtualization functions to the guest VM. That means that you can install a hypervisor, such as Oracle VM VirtualBox, Oracle VM Server or KVM, on an Oracle VM VirtualBox guest. You can then create and run VMs within the guest VM.
>
> However, when running [kvm-ok](https://manpages.debian.org/bookworm/cpu-checker/kvm-ok.1.en.html) it's reporting KVM virtualization is not available, even though the Intel processor in my Mac [should support it](https://ark.intel.com/content/www/us/en/ark/products/191046/intel-core-i7-9750hf-processor-12m-cache-up-to-4-50-ghz.html).

Starting from a fresh VM.

1. Create VM in VirtualBox, using [debian-12.5.0-amd64-DVD-1.iso](https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/) (and validate the sha)
    1. change login to `debian`/`debian`
    1. select `Guest Additions`
    1. allocate 8GB RAM, 4 CPUs
    1. set disk space to 50GB (but don't pre-allocate)
1. Add user to sudoers
    1. `sudo visudo -f /etc/sudoers` or `su -` then `visudo -f /etc/sudoers`
    1. add `<user> ALL=(ALL:ALL) ALL` under the similar line for `root`
1. Fix sources list for apt/apt-get
    1. `vi /etc/apt/sources.list`
    1. Comment out the exising line:  `# deb cdrom ...`
    1. Add the example values [here](https://wiki.debian.org/SourcesList):
    ```
    deb http://deb.debian.org/debian bookworm main non-free-firmware
    deb-src http://deb.debian.org/debian bookworm main non-free-firmware

    deb http://deb.debian.org/debian-security/ bookworm-security main non-free-firmware
    deb-src http://deb.debian.org/debian-security/ bookworm-security main non-free-firmware

    deb http://deb.debian.org/debian bookworm-updates main non-free-firmware
    deb-src http://deb.debian.org/debian bookworm-updates main non-free-firmware
    ````
1. Set nested virtualization config in VirtualBox
    1. Shut down VM
    1. `VBoxManage modifyvm <vm-name> --nested-hw-virt on`
    1. Restart VM
1. Verify KVM virtualization is available via any of:
    1. `lsmod | grep kvm`
    1. `egrep "svm|vmx" /proc/cpuinfo`
    1. `sudo kvm-ok` (install via `sudo apt-get install cpu-checker`)
1. Manually install git (to clone this repo with the scripts)
    1. `sudo apt-get install -y git`
1. Clone this repo
    1. `git clone https://github.com/davidkuster/firecracker-containerd-experiment`
1. Run these scripts (slightly tweaked versions of the firecracker-containerd [getting started](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/getting-started.md) instructions):
    1. `scripts/debian/fc-setup.sh` ([source](scripts/debian/fc-setup.sh))
    1. `scripts/docker-fix-disk-space.sh` ([source](scripts/ubuntu/docker-fix-disk-space.sh)) (preemptively fix Docker disk space issues)
    1. `scripts/debian/fc-install.sh` ([source](scripts/debian/fc-install.sh))
        - this command especially will dump out a ton of logs
        - it may complain `device-mapper: reload iotcl on fc-dev-thinpool  failed: No such device or address` but this can be ignored if the `firecracker-runtime.json` output is shown in the next step
1. Start firecracker-containerd (getting started step 5)
    1. `sudo firecracker-containerd --config /etc/firecracker-containerd/config.toml`
1. In another window run the commands in getting started step 6
    ```bash
    sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock \
        image pull \
        --snapshotter devmapper \
        docker.io/library/debian:latest
    ```
    This is successful for me.

    ```bash
    sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock \
        run \
        --snapshotter devmapper \
        --runtime aws.firecracker \
        --rm --tty --net-host \
        docker.io/library/debian:latest \
        test
    ```
    This fails:
    > ctr: failed to start shim: start failed: aws.firecracker: unexpected error from CreateVM: rpc error: code = Unknown desc = failed to create VM: failed to start the VM: Put "http://localhost/actions": EOF: exit status 1: unknown

    See [logs section](#logs) for a (so far unsuccessful) attempt to get more information about this error.

### Random

#### DNS

I've now had DNS fail twice on me after running the `firecracker-ctr ... test` command more than once. I'm able to ping IPs but have to replace my local nameserver config in `/etc/resolve.conf` with those from Google:
```
# Generated by NetworkManager
search attlocal.net
#nameserver 192.168.1.254
nameserver 8.8.8.8
nameserver 8.8.4.4
```
Weird.

#### Logs

Trying to see in the logs what's happening with the unknown error above. But it looks like while `log_fifo` is still in the doc that's been renamed to `log_path` in the code. Attempting this config in `/etc/containerd/firecracker-runtime.json` but unable to get it to create a log file so far:
```json
{
  "firecracker_binary_path": "/usr/local/bin/firecracker",
  "cpu_template": "T2",
  "log_path": "/tmp/fc-logs.fifo",
  "level": "Debug",
  "show_level": true,
  "metrics_path": "/tmp/fc-metrics.fifo",
  "kernel_args": "console=ttyS0 noapic reboot=k panic=1 pci=off nomodules ro systemd.unified_cgroup_hierarchy=0 systemd.journald.forward_to_console systemd.unit=firecracker.target init=/sbin/overlay-init",
  "default_network_interfaces": [{
    "CNIConfig": {
      "NetworkName": "fcnet",
      "InterfaceName": "veth0"
    }
  }]
}
```

But, it's also been this way in Firecracker since 5 Aug 2020 with the [v0.22.0 release](https://github.com/firecracker-microvm/firecracker/releases/tag/v0.22.0). Is the firecracker-containerd quickstart that out of date?


### Ubuntu (live USB)

Starting fresh from an Ubuntu 22.04 (Jammy Jellyfish) live USB.

1. `sudo apt-get update`
1. Manually install git (to clone this repo with the scripts)
    1. `sudo apt-get install -y git`
1. Clone this repo
    1. `git clone https://github.com/davidkuster/firecracker-containerd-experiment`
1. Follow the firecracker-containerd [getting started](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/getting-started.md) instructions, included in this repo as slightly tweaked scripts:
    1. `scripts/ubuntu/fc-setup.sh` ([source](scripts/ubuntu/fc-setup.sh))
    1. `scripts/docker-fix-disk-space.sh` ([source](scripts/ubuntu/docker-fix-disk-space.sh)) (preemptively fix Docker disk space issues)
    1. `sudo scripts/ubuntu/fc-install.sh` ([source](scripts/ubuntu/fc-install.sh))
        - note the `sudo` here so that the Docker commands will work
        - current status
            - [this command](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/tools/image-builder/Makefile#L46-L55) in the `tools/image-builder/Makefile` returns an error:
            ```bash
            debootstrap --variant=minbase --include=udev,systemd,systemd-sysv,procps,libseccomp2,haveged bullseye "tmp/rootfs" http://deb.debian.org/debian
            /usr/sbin/debootstrap: 1723: cannot create /src/tmp/rootfs/test-dev-null: Permission denied
            E: Cannot install into target '/src/tmp/rootfs' mounted with noexec or nodev
            make: *** [Makefile:81: debootstrap_stamp] Error 1
            make[1]: *** [Makefile:119: all-in-docker] Error 2
            make[1]: Leaving directory '/root/firecracker-containerd/tools/image-builder'
            make: *** [Makefile:166: image] Error 2
            ```


## References

- firecracker-containerd [quickstart](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/quickstart.md)
- firecracker-containerd [getting started](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/getting-started.md)
- [Getting Started with Firecracker](https://medium.com/better-programming/getting-started-with-firecracker-a88495d656d9)
- firecracker-containerd [issue](https://github.com/firecracker-microvm/firecracker-containerd/issues/472) on quickstart and Ubuntu
