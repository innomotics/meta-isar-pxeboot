# meta-isar-pxeboot: A PXE Boot Setup for ISAR based images

This repo contains the recipes used to build a PXE boot environment for ISAR based images.

The build system used for this is [Isar](https://github.com/ilbers/isar), an image generator that assembles Debian binaries or builds individual packages from scratch.


Documentation on how to install images on target devices can be found in [docs/user-quickstart.md](docs/user-quickstart.md)
For more technical deep dive you can have a look at [docs/pxe-boot-installer.md](docs/pxe-boot-installer.md).



## Build

To build the PXE Boot Server image (containing the target image to be executed on device) run:

```
./kas-container build kas-pxe-boot.yml
```

> **Note:** If you want to build without using containers you can follow the instructions to setup the isar build dependencies here: https://github.com/ilbers/isar/blob/master/doc/user_manual.md#getting-started
>
> In addition you should also install kas (either `apt install kas` or manually via `pip install kas` for latest versions)
>
> Caveat: For Debian 12 or later and Ubuntu 24.04 or later, pip install must be executed within a virtual environment (venv).
>
> ```
> python3 -m venv .venv
> source .venv/bin/activate
> pip3 install kas
> ```

### Build time optimizations (optional)

To improve build times by using cached upstream apt artifacts you can setup an apt cache as described in [docs/setup-build-env/apt-caching-proxy.md](docs/setup-build-env/apt-caching-proxy.md).

## Testing

### System Test Setup

1. Configure a local bridge network used for the pxe-boot setup:

    ```
    ./scripts/qemu-test/1-setup-network.sh
    ```

1. Start the pxe boot server:

    ```
    ./scripts/qemu-test/2-start-pxe-boot-server.sh
    ```

1. Start the target vm:

    ```
    ./scripts/qemu-test/3-start-target.sh
    ```

1. Once you are done testing you can remove the network setup again:

    ```
    ./scripts/qemu-test/4-remove-network.sh
    ```

### Automated On-Device bats Tests

The bats test files in `tests/` can be included to the PXE server enabling `PXE_SERVER_INCLUDE_TESTS` in Kconfig or
by adding `kas/opt/include-tests-pxe-server.yml` to `./kas-container build ...` invokation.

```
./kas-container build kas-pxe-boot.yml:kas/opt/include-tests-pxe-server.yml
```

Once the image is running, SSH in and execute:

```bash
run_tests               # TAP output
run_tests_debug         # verbose output (failing tests only)
run_tests_debug_all     # verbose output (all tests)
run_tests_lava          # LAVA-formatted output
```

## Credits

* Developed by Innomotics GmbH & Siemens AG
* Sponsored by Innomotics GmbH
