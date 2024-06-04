# firecracker-containerd-experiment

## Objective

Use FirecrackerVM / firecracker-containerd as an isolation wrapper around Docker containers.


## Experiment notes

Running both Ubuntu 22.04 (Jammy Jellyfish) from a live USB disk and Debian 12 (bookworm) in VirtualBox on a Mac. Initially started with Ubuntu because I'm more familiar with it but the [firecracker-containerd quickstart](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/quickstart.md) is Debian-oriented so I may be swimming against the tide with Ubuntu.


### Debian

Starting from a fresh VM.

1. Create VM in VirtualBox, using [debian-12.5.0-amd64-DVD-1.iso](https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/) (and validate the sha)
    1. change login to `debian`/`debian`
    1. select `Guest Additions`
    1. allocate 8GB RAM, 4 CPUs
    1. set disk space to 50GB (but don't pre-allocate)
1. Shut down VM
1. Set nested virtualization (`VBoxManage modifyvm <vm-name> --nested-hw-virt on`)
1. Restart VM
1. Add user to sudoers
    1. `su -`
    1. `visudo -f /etc/sudoers`
    1. add `<user> ALL=(ALL:ALL) ALL)` under the similar line for `root`
    1. `exit` to quit root shell
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
1. Follow the firecracker-containerd [getting started](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/getting-started.md) instructions, included in this repo as slightly tweaked scripts:
    1. Run [fc-setup-debian.sh](scripts/fc-setup-debian.sh)
    1. Run [fc-install-debian.sh](scripts/fc-install-debian.sh)
        - this command especially will dump out a ton of logs
        - current status
            - this bit (I think)
            ```shell
            if ! $(sudo dmsetup reload "${POOL}" --table "${THINP_TABLE}"); then
                sudo dmsetup create "${POOL}" --table "${THINP_TABLE}"
            fi
            ```
            results in:
            ```shell
            0 209715200 thin-pool /dev/loop1 /dev/loop0 128 32768 1 skip_block_zeroing
            device-mapper: reload ioctl on fc-dev-thinpool  failed: No such device or address
            ```


## References

- [Getting Started with Firecracker](https://medium.com/better-programming/getting-started-with-firecracker-a88495d656d9)
- firecracker-containerd [quickstart](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/quickstart.md)
- firecracker-containerd [getting started](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/getting-started.md)
