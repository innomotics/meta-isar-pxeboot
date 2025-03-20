# Setup Squid as APT Caching Proxy

Limited download bandwitdth oftentimes is an issue, and increases the build times drastically. Further, large corporate networks could get rate limited by debian mirrors, as many people / pipelines / aso. fetch huge amounts of packets from there.

In such cases a proxy caching the packages is quite useful as it reduces download times and reduces pressure on debian mirrors.

## Install Squid Proxy
```
apt install squid
```

## Configure Proxy for Caching (with APT in mind)

1. /etc/squid/squid.conf
This file contains the main configuration for `squid`.
We configure it to listen to port `4242` and cache all requests from sites listed in `/etc/squid/mirror-dstdomain.acl`. Further, to enable, offline usecases (or usecases where your ip got temporarily blacklisted by `snapshot.debian.org` or similar) we set `offline_mode on`
to not fetch already cached packages from upstream.

> Note: While `offline_mode on` is totally fine for `snapshot.debian.org` when using a timestamp to fix your package archive version, this could cause unintended behaviour (most probably outdated packages) when used against a non archive mirror.

> Hint: If you are planning to work against non archive mirrors, and you are not sure, it's recommended to set `offline_mode off` and probably tweak cache behaviour with a `refresh_pattern`.

### /etc/squid/squid.conf:
```
# File: /etc/squid/squid.conf

# default to a different port than stock squid
http_port 4242

# user visible name
visible_hostname squid-apt-caching-proxy

# do not fetch already cached packages from upstream
offline_mode on

# we need a big cache, some debs are huge
maximum_object_size 512 MB

# increase available disk space for cache dir to 40G
cache_dir aufs /var/cache/squid 40000 16 256

# logs
access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log
cache_store_log /var/log/squid/store.log

# tweaks to speed things up
cache_mem 256 MB
maximum_object_size_in_memory 10240 KB

# only allow ports we trust
acl Safe_ports port 80
acl Safe_ports port 443

http_access deny !Safe_ports

# Deny access to blacklisted sites
acl blockedpkgs urlpath_regex "/etc/squid/pkg-blacklist-regexp.acl"
http_access deny blockedpkgs

# List of domains to cache
acl to_archive_mirrors dstdomain "/etc/squid/mirror-dstdomain.acl"
# don't cache domains not listed in the mirrors file
cache deny !to_archive_mirrors

# Allow access to the proxy only from networks listed in allowed-networks-src.acl
acl allowed_networks src "/etc/squid/allowed-networks-src.acl"
http_access allow allowed_networks

# And finally deny all other access to this proxy
http_access deny all
```

### /etc/squid/mirror-dstdomain.acl:
```
# File: /etc/squid/mirror-dstdomain.acl

snapshot.debian.org
```

### /etc/squid/pkg-blacklist-regexp.acl:
```
# File: /etc/squid/pkg-blacklist-regexp.acl
# Empty for now
```

### /etc/squid/allowed-networks-src.acl:
```
# File: /etc/squid/allowed-networks-src.acl 

# network sources that you want to allow access to the cache

# private networks
10.0.0.0/8 
172.16.0.0/12
192.168.0.0/16
127.0.0.1

# IPv6 private addresses
fe80::/64
::1/128

# IPv6 mesh local
fd00::/8
```

Restart `systemctl restart squid`

> Note: Depending on your distribution and the exact package you are using
> you may have to set the right access rights for the proxy:
> ```
> chgrp proxy /var/cache/squid/
> ```

## Use the Proxy in ISAR Build System

To forward the proxy settings to apt inside the ISAR build system just export `http_proxy`
as follows:

```
export http_proxy=http://<proxy-server-ip>:4242
```

> Hint: Consider also setting `https_proxy`.

### Validation

The first time you build your image the cache will fetch all packages from upstream.
During that phase you will see log entries, like

```
... TCP_MISS/200 1574478 GET http://snapshot.debian.org/file/7cfaf...
```
in `/var/log/squid/access.log`.

From that time on for existing packages only 

```
... TCP_OFFLINE_HIT/200 1574480 GET http://snapshot.debian.org/file/7cfaf...
... TCP_MEM_HIT/200 1574480 GET http://snapshot.debian.org/file/7cfaf...
```

> Note: When you add new packages to your image, these have to be fetched first, so you will encounter `TCP_MISS`es whenever you add packages you didn't fetched before. Same holds true when upgrading the snapshot timestamp (`ISAR_APT_SNAPSHOT_TIMESTAMP` or `ISAR_APT_SNAPSHOT_DATE`).

> Hint: You can observe your cache misses using: 
> ```
> tail -f /var/log/squid/access.log | grep -e TCP_MEM_HIT -e TCP_OFFLINE_HIT -v
> ```
