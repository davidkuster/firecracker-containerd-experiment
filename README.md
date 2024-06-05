# firecracker-containerd-experiment

## Objective

Use FirecrackerVM / firecracker-containerd as an isolation wrapper around Docker containers.


## Experiment notes

Running both Ubuntu 22.04 (Jammy Jellyfish) from a live USB disk and Debian 12 (bookworm) in VirtualBox on a Mac. Initially started with Ubuntu because I'm more familiar with it but the [firecracker-containerd quickstart](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/quickstart.md) is Debian-oriented so I may be swimming against the tide with Ubuntu.

- [Debian](#debian)
- [Ubuntu](#ubuntu)


### Debian

> Update: doing this in VirtualBox may be a red herring, and turning on nested virtualization presumably doesn't work as expected. [kvm-ok](https://manpages.debian.org/bookworm/cpu-checker/kvm-ok.1.en.html) did not fail to install - it can only be run as root. Running `sudo kvm-ok` on my VM now reports the following: `INFO: Your CPU does not support KVM extensions. KVM acceleration can NOT be used.` Unfortunately the error message from firecracker-containerd in this situation is just "unknown" instead of something useful. (And, `lsmod | grep kvm` is an even easier quick verification before starting.)

> Update2: VirtualBox [doc](https://docs.oracle.com/en/virtualization/virtualbox/7.0/user/AdvancedTopics.html) indicates this should work:
>> Oracle VM VirtualBox supports nested virtualization. This feature enables the passthrough of hardware virtualization functions to the guest VM. That means that you can install a hypervisor, such as Oracle VM VirtualBox, Oracle VM Server or KVM, on an Oracle VM VirtualBox guest. You can then create and run VMs within the guest VM.


Starting from a fresh VM.

1. Create VM in VirtualBox, using [debian-12.5.0-amd64-DVD-1.iso](https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/) (and validate the sha)
    1. change login to `debian`/`debian`
    1. select `Guest Additions`
    1. allocate 8GB RAM, 4 CPUs
    1. set disk space to 50GB (but don't pre-allocate)
1. Add user to sudoers
    1. `sudo visudo -f /etc/sudoers`
    1. add `<user> ALL=(ALL:ALL) ALL)` under the similar line for `root`
1. Fix sources list for apt/apt-get
    1. Comment out the exising `deb cdrom ...` line
    1. Add the example values [here](https://wiki.debian.org/SourcesList):
    ```
    deb http://deb.debian.org/debian bookworm main non-free-firmware
    deb-src http://deb.debian.org/debian bookworm main non-free-firmware

    deb http://deb.debian.org/debian-security/ bookworm-security main non-free-firmware
    deb-src http://deb.debian.org/debian-security/ bookworm-security main non-free-firmware

    deb http://deb.debian.org/debian bookworm-updates main non-free-firmware
    deb-src http://deb.debian.org/debian bookworm-updates main non-free-firmware
    ````
1. Manually install git (to clone this repo with the scripts)
    1. `sudo apt-get install -y git`
1. Clone this repo
    1. `git clone https://github.com/davidkuster/firecracker-containerd-experiment`
1. Install [KVM](https://wiki.debian.org/KVM)
    1. Run [scripts/debian/kvm-install.sh](scripts/debian/kvm-install.sh)
    1. _TBD if this is needed_
1. Shut down VM
1. Set nested virtualization (`VBoxManage modifyvm <vm-name> --nested-hw-virt on`)
1. Restart VM
1. Verify KVM virtualization is available via any of:
    1. `lsmod | grep kvm`
    1. `egrep "svm|vmx" /proc/cpuinfo`
    1. `sudo kvm-ok` (install via `sudo apt-get install cpu-checker`)
1. Follow the firecracker-containerd [getting started](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/getting-started.md) instructions, included in this repo as slightly tweaked scripts:
    1. Run [scripts/fc-setup-debian.sh](scripts/fc-setup-debian.sh)
    1. Run [scripts/fc-install-debian.sh](scripts/fc-install-debian.sh)
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


### Ubuntu

Starting fresh from an Ubuntu 22.04 (Jammy Jellyfish) live USB.

1. `sudo apt-get update`
1. Manually install git (to clone this repo with the scripts)
    1. `sudo apt-get install -y git`
1. Clone this repo
    1. `git clone https://github.com/davidkuster/firecracker-containerd-experiment`
1. Follow the firecracker-containerd [getting started](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/getting-started.md) instructions, included in this repo as slightly tweaked scripts:
    1. Run [scripts/ubuntu/fc-setup.sh](scripts/ubuntu/fc-setup.sh)
    1. Run [scripts/ubuntu/docker-fix-disk-space.sh](scripts/ubuntu/docker-fix-disk-space.sh) (preemptively fix Docker disk space issues)
    1. Run "sudo [scripts/ubuntu/fc-install.sh](scripts/ubuntu/fc-install.sh)"
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
