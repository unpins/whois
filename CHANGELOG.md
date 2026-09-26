# Changelog

## [Unreleased]

### Added

- On Linux, hostnames now resolve on a machine whose DNS resolver is missing or
  unreachable — Android, or a container with no `/etc/resolv.conf` — once you
  point unpins at a name server. Before, every lookup failed there and the
  query never left the machine.

### Changed

- Built by the same compiler as the rest of the catalog. The Linux x86_64
  binary grew from 632 KB to 690 KB; behaviour is unchanged.
