{ unpins-lib }:
pkgs:
let
  cosmoPkgs = unpins-lib.lib.cosmoStaticCross pkgs; # = pkgs.pkgsCross.cosmo
in
(cosmoPkgs.whois.override {
  # libidn2 drags libunistring, whose gnulib getlocalename_l-unsafe.c has no
  # Cosmopolitan port (build dies with `#error "Please port ... to your
  # platform!"`). whois builds and runs fine without it — the only loss is IDN
  # (non-ASCII domain name → punycode) conversion before the query. Linux/macOS
  # keep libidn2; this degradation is Windows-only.
  libidn2 = null;
}).overrideAttrs (oa: {
  # Same config.h portability fix as the native build (getopt_long /
  # getaddrinfo are present on Cosmopolitan but its libc-detection blocks miss
  # them). See whois-portability.patch.
  patches = (oa.patches or [ ]) ++ [ ./whois-portability.patch ];
})
