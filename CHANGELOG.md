# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

Initial release of `meta-isar-pxeboot`, an ISAR meta-layer that builds a
ready-to-run PXE boot server appliance which network-installs an ISAR-built
image onto a target device.

### Added

#### PXE server appliance

- `pxe-boot-server` image bundling everything required to provision devices on
  an isolated network: dnsmasq (DHCP, DNS, TFTP), nginx for HTTP delivery of
  boot files and image artifacts, and the boot chain for UEFI clients.
- `pxe-setup` recipe providing the dnsmasq and `systemd-networkd`
  configuration. Network parameters (`PXESERVER_INTERFACE_NAMES`,
  `PXESERVER_IP`, `PXESERVER_NETMASK`, `PXESERVER_DHCP_RANGE_START`,
  `PXESERVER_DHCP_RANGE_END`) are templated into the image at build time.
- Optional NFS root filesystem (`nfs-installer-rootfs`) for serving the
  installer image over NFS instead of embedding it in the initrd.

#### Boot chain variants

- **iPXE with embedded script** (default): `ipxe.efi` is built from source with
  the boot script compiled in; the client fetches kernel, initrd and image over
  HTTP.
- **iPXE with autoexec script**: the boot script is fetched from the server at
  runtime, so it can be changed without rebuilding `ipxe.efi`.
- **syslinux over TFTP**: slower fallback for NICs that do not work with iPXE.

  Selected via the `ipxe-embedded`, `ipxe-autoexec` and `pxe-syslinux`
  overrides, exposed as kas fragments and Kconfig options.

#### Installation

- Unattended installation mode: target device, image artifact and overwrite
  policy are handed to the installer via kernel command line
  (`INSTALLER_TARGET_DEVICE`, defaulting to `/dev/sda:/dev/nvme0n1`).
- Interactive installation mode when unattended mode is disabled.
- BitBake multiconfig setup (`pxe-boot-server`, `pxe-boot-installer`,
  `pxe-boot-installer-target`) that builds the server appliance and the target
  image to be deployed in a single invocation.

#### Dual use: standalone and embedded

- Standalone builds ship `pxe-boot-target-demo`, a demo image,
  so the layer can be built and tested on its own.
- When embedded into a product repository, `INSTALLER_TARGET_IMAGE`,
  `PXE_TARGET_MACHINE` and the multiconfig settings can be overridden to deploy
  an arbitrary Isar image. `isar-image-base` and `isar-image-debug` are
  selectable out of the box.

#### Build configuration

- kas entry points for the supported deployment formats:
  - `kas-pxe-boot.yml` — QEMU AMD64 `.wic` image
  - `kas-pxe-boot-virtualbox-example.yml` — VirtualBox `.ova`
  - `kas-pxe-boot-vmware-example.yml` — VMware `.ova`
- Interactive configuration via `./kas-container menu` (Kconfig), covering
  Debian release (bookworm, trixie), package feeds, server and target machine,
  boot chain variant, VM sizing for OVA output, and additional features.
- Target machine support for QEMU AMD64, VirtualBox, VMware and generic x86 PC.
- Optional features: serial debug console, root user enablement for server and
  target, extra preinstalled packages, and a debug image variant.
- Reproducible builds against a pinned `snapshot.debian.org` timestamp, with
  optional Artifactory proxy support.

#### Testing

- Host-side QEMU integration scripts under `scripts/qemu-test/` to set up a
  bridged network, start the PXE server VM, boot a target VM against it and
  tear the network down again.
- bats test suite packaged into the server image via the optional
  `pxe-server-tests` recipe, covering base system state, dnsmasq, nginx, TFTP
  and NFS. Runnable on the device through `run_tests`, `run_tests_debug`,
  `run_tests_debug_all` and `run_tests_lava` (LAVA-compatible output).
- GitLab CI pipeline building the qemuamd64, VirtualBox and VMware variants
  against a pinned Debian snapshot, plus a GitHub Actions CI pipeline.

#### Documentation and project files

- User quickstart (`docs/user-quickstart.md`) and technical deep dive
  (`docs/pxe-boot-installer.md`).
- Guide for setting up an apt caching proxy to speed up rebuilds.
- MIT `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`,
  `SUPPORT.md`, `MAINTAINERS`, this changelog, and GitHub issue and pull
  request templates.
