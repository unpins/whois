# whois

Standalone build of [whois](https://github.com/rfc1036/whois) — the intelligent WHOIS client from Debian.

[![CI](https://github.com/unpins/whois/actions/workflows/whois.yml/badge.svg)](https://github.com/unpins/whois/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

## Usage

Run the `whois` program with [unpin](https://github.com/unpins/unpin):

```bash
unpin whois example.com
```

To install it onto your PATH:

```bash
unpin install whois
```

It picks the appropriate WHOIS server for most queries automatically; pass `-h <server>` to override.

## Build locally

```bash
nix build github:unpins/whois
./result/bin/whois example.com
```

Or run directly:

```bash
nix run github:unpins/whois -- example.com
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/whois/releases) page has standalone binaries for manual download.

## Man pages

`whois.1` and `whois.conf.5` are embedded in the binary — read them with `unpin man whois` and `unpin man whois whois.conf`.

## Build notes

- **Windows** uses [Cosmopolitan](https://justine.lol/cosmopolitan/) (cosmocc), not mingw. whois is a pure BSD-socket client — its source includes `<sys/socket.h>`, `<netinet/in.h>` and `<netdb.h>` directly, which mingw-w64 doesn't provide (the mingw cross fails at the first `#include`). Cosmopolitan's libc implements those sockets over winsock internally, so the same source compiles and the binary queries servers natively on Windows.
- **IDN (internationalized domain names)** are converted to punycode via `libidn2` on Linux and macOS. The Windows build drops `libidn2` — its `libunistring` dependency has no Cosmopolitan port — so a non-ASCII domain must be entered already-encoded there. ASCII queries are unaffected.
- The musl (Linux) and Cosmopolitan (Windows) libcs both support `getopt_long` and `getaddrinfo`, but whois's hand-maintained `config.h` only enables them for glibc/Apple/BSD. A small portability patch turns them on so long options (`--host`, `--verbose`, `--version`, …) and IPv6 resolution work on every target.
