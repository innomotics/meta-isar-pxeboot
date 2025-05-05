# meta-isar-pxeboot: A PXE Boot Setup for ISAR based images

This repo contains the recipes used to build a PXE boot environment for ISAR based images.

The build system used for this is [Isar](https://github.com/ilbers/isar), an image generator that assembles Debian binaries or builds individual packages from scratch.


Documentation on how to install images on target devices can be found in [docs/user-quickstart.md](docs/user-quickstart.md)
For more technical deep dive you can have a look at [docs/pxe-boot-installer.md](docs/pxe-boot-installer.md).



## Build

To build the PXE Boot Server image (containing the target image to be executed on device) run:

```
./build.sh kas-pxe-boot.yml
```

> Hint: For easier reproducibility you can put exported variables needed for the build in a `.env` file in the local directory or put global settings in `/etc/meta-pxe-boot.env`. The `./build.sh` script will source them before invoking the build.

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

