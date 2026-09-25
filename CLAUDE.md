# meta-isar-pxeboot

## Overview

This is an **ISAR meta-layer** that builds a PXE boot server image. It is used in two modes:

- **Embedded (primary use):** consumed as a layer inside a larger OS repo that provides its own target image. That outer repo overrides `INSTALLER_TARGET_IMAGE`, `PXE_TARGET_MACHINE`, and multiconfig settings.
- **Standalone:** builds a self-contained demo using `pxe-boot-target-demo` (a CIP Core-based image).

Build system: **Isar** (BitBake-based, Debian-centric image builder) composed via **kas** (YAML-based build configurator). Languages in this repo: BitBake recipes (`.bb`), kas YAML, bash scripts, bats tests.

Reference docs:

- End-user install guide: `docs/user-quickstart.md`
- Technical deep-dive: `docs/pxe-boot-installer.md`

---

## Repository Structure

| Path | Purpose |
| --- | --- |
| `recipes-core/pxe-setup/` | Main PXE server setup recipe: installs dnsmasq config, iPXE/syslinux boot files, systemd-networkd config |
| `recipes-core/ipxe-efi/` | Builds `ipxe.efi` from source |
| `recipes-core/ipxe-bootfiles-http-server/` | nginx recipe serving iPXE boot scripts over HTTP |
| `recipes-core/nfs-server-rootfs/` | NFS rootfs recipe for serving the installer image |
| `recipes-testing/pxe-server-tests/` | Packages the bats test suite into the image (opt-in) |
| `kas/` | kas YAML fragments: `common/`, `distro/`, `opt/`, `pxe-server-machine/`, `pxe-target-machine/` |
| `conf/` | `layer.conf` (BitBake layer registration), `multiconfig/` (`pxe-boot-server`, `pxe-boot-installer`, `pxe-boot-installer-target`) |
| `tests/` | bats test files — **run on the deployed image, not on the build host** |
| `scripts/qemu-test/` | Host-side scripts for local QEMU integration testing |
| `isar/` | Git submodule — upstream Isar framework (pinned commit, see below) |
| `Kconfig` | Interactive build config menu (`kas menu`) |
| `docs/` | User quickstart, technical deep-dive, architecture assets |

---

## Build

### Prerequisites

- Docker (used by `kas-container`)
- No other local dependencies required for container builds

### Commands

```bash
# Default build (QEMU AMD64 server + QEMU target)
./kas-container build kas-pxe-boot.yml

# VirtualBox OVA
./kas-container build kas-pxe-boot-virtualbox-example.yml

# VMware OVA
./kas-container build kas-pxe-boot-vmware-example.yml

# Interactive config (uses Kconfig)
./kas-container menu
```

### Build Output

```text
build/tmp-pxe-boot-server-<machine>/deploy/images/<machine>/
```

For QEMU: `pxe-boot-server-debian-bookworm-qemuamd64.wic`
For VirtualBox/VMware: `pxe-boot-server-debian-bookworm-<machine>.ova`

### kas YAML Composition

kas YAMLs compose via `header.includes`. The three entry-point files (`kas-pxe-boot.yml`, `kas-pxe-boot-virtualbox-example.yml`, `kas-pxe-boot-vmware-example.yml`) each pull in fragments from `kas/common/`, `kas/distro/`, `kas/opt/`, and machine subdirs. Include order matters — later includes can override earlier settings.

### Multiconfig

The build produces two images coordinated via BitBake multiconfig:

- `pxe-boot-server` — the PXE server appliance
- `pxe-boot-installer-target` — the target OS image embedded in the server

---

## Test Workflow

### Local QEMU Test Loop

```bash
# 1. Build
./kas-container build kas-pxe-boot.yml

# 2. Set up a bridge network for QEMU
./scripts/qemu-test/1-setup-network.sh

# 3. Start the PXE server VM
./scripts/qemu-test/2-start-pxe-boot-server.sh

# 4. Start the target VM (will PXE-boot from the server)
./scripts/qemu-test/3-start-target.sh

# 5. Tear down when done
./scripts/qemu-test/4-remove-network.sh
```

### On-Device bats Tests

The bats test files in `tests/` are **not run on the build host**. They are packaged into the PXE server image by the `pxe-server-tests` recipe and run inside the deployed image.

The recipe is **not included by default**. To include it, add `kas/opt/include-tests-pxe-server.yml` to your kas config (or enable `PXE_SERVER_INCLUDE_TESTS` in Kconfig).

Once the image is running, SSH in and execute:

```bash
run_tests               # TAP output
run_tests_debug         # verbose output (failing tests only)
run_tests_debug_all     # verbose output (all tests)
run_tests_lava          # LAVA-formatted output
```

### CI

GitLab CI (`.gitlab-ci.yml`) runs three builds: qemuamd64, virtualbox, vmware. It uses a pinned Debian snapshot (`DEBIAN_SNAPSHOT`) for reproducibility. The snapshot date is an input to the CI pipeline.

---

## Key Conventions and Gotchas

### OVERRIDES naming — load-bearing, highest risk

ISAR recipe conditionals use `OVERRIDES` tokens. Typos cause **silent wrong behavior** at build time. The tokens in use in this layer:

| Override token | Effect |
| --- | --- |
| `ipxe-embedded` | iPXE boots using a script embedded at build time (default) |
| `ipxe-autoexec` | iPXE fetches its boot script from the server at runtime |
| `pxe-syslinux` | Use syslinux over TFTP instead of iPXE (slower, for NIC compatibility) |
| `pxe-nfsroot` | Enable NFS rootfs for the installer image |

These tokens are set via `OVERRIDES:append` in kas YAML `local_conf_header` blocks. Recipe syntax like `:remove:pxe-syslinux` and `:append:ipxe-autoexec` depends on exact spelling — a wrong token silently falls back to the default instead of erroring.

### isar submodule pin — do not bump without testing

The isar submodule commit is pinned in `kas/common/base.yml`:

```yaml
repos:
  isar:
    url: https://github.com/ilbers/isar.git
    commit: 9e62337953fbb8371c846c44e8a99d62a8d220ba
```

**Do not change this commit without running a full build and QEMU test.** Isar upstream regularly makes breaking changes to recipe APIs and BitBake variable names.

### TEMPLATE_VARS must exactly match template placeholders

Recipes that use `dpkg-raw` with `.tmpl` files (e.g. `pxe-setup.bb`) expand `TEMPLATE_VARS` into the installed config files at build time. The variable names in `TEMPLATE_VARS` must exactly match the placeholder names in the corresponding `.tmpl` files.

A mismatch does **not** cause a build error — it produces a config file with unexpanded placeholders that fails silently at runtime. Always verify both sides when adding or renaming a template variable.

---

## Dual-Use: Standalone vs. Embedded

When this layer is used standalone, `INSTALLER_TARGET_IMAGE` defaults to `pxe-boot-target-demo` (defined in `Kconfig`). When embedded in an OS repo, the outer repo overrides this and other target settings.

Variables that affect both use cases (defaults in `recipes-core/pxe-setup/pxe-setup.bb`, some also in `Kconfig`):

- `INSTALLER_TARGET_IMAGE`
- `PXE_TARGET_MACHINE`
- `PXESERVER_INTERFACE_NAMES`, `PXESERVER_IP`, `PXESERVER_NETMASK`
- `PXESERVER_DHCP_RANGE_START`, `PXESERVER_DHCP_RANGE_END`

Changes to these variable names or defaults affect both use cases.
