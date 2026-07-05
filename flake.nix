{
  description = "whois as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Native Linux/macOS comes from pkgsStatic.whois. Windows uses cosmocc, not
  # mingw: whois (rfc1036/whois) is a pure BSD-socket client — whois.c includes
  # <sys/socket.h>, <netinet/in.h>, <netdb.h>, <unistd.h> directly with no
  # winsock/_WIN32 guards anywhere in the tree. The mingw cross fails immediately
  # ("sys/socket.h: No such file or directory"); mingw-w64 has no POSIX socket
  # headers — Windows networking goes through winsock2 + WSAStartup, which
  # upstream doesn't speak. Porting that is the same open-ended winsock rewrite
  # that keeps git on the mingw WIP shelf. Cosmopolitan's libc implements BSD
  # sockets on Windows over winsock internally (superconfigure ships
  # curl/wget/openssh this way), so the cosmo cross compiles whois.c unchanged.
  # The cosmo recipe (drop libidn2) lives in ./cosmo.nix.
  #
  # whois-portability.patch fixes a real bug on both: whois's hand-maintained
  # config.h only enables getopt_long()/getaddrinfo() for glibc / Apple / *BSD,
  # so on musl (pkgsStatic) and Cosmopolitan it silently loses every long option
  # and falls back to legacy gethostbyname(). See the patch header.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      dnsFallback = true; # resolves hostnames; opt into the Android DNS fallback
      name = "whois";
      # whois has no -V/--version short form (-V sets the client tag); the long
      # `--version` only works once whois-portability.patch turns on
      # getopt_long. Banner is "Version 5.6.6." — match on the stable prefix.
      smoke = [ "--version" ];
      smokePattern = "Version";
      build = pkgs:
        let
          inherit (pkgs) lib;
          isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
          # GNU libiconv. On darwin nixpkgs builds the whole libidn2/libunistring
          # stack against it, and it exports the `libiconv`-prefixed workers.
          gnuIconv = pkgs.pkgsStatic.libiconvReal;
        in
        pkgs.pkgsStatic.whois.overrideAttrs (oa: {
          patches = (oa.patches or [ ]) ++ [ ./whois-portability.patch ];
          # Darwin iconv reconciliation. libidn2 pulls libunistring, whose
          # striconveh.o references the GNU `libiconv`-prefixed symbols (_libiconv /
          # _libiconv_open / _libiconv_close), because nixpkgs builds the whole
          # libidn2/libunistring stack against GNU libiconv even in the static set.
          # Apple's system libiconv exports only plain iconv (+ the _libiconv_version
          # data symbol). On musl-linux iconv is in libc and libunistring uses the
          # plain names, so `-lidn2 -lunistring` just links — this whole block is
          # darwin-only. On darwin, whois has no multicall so its build takes the
          # non-engine iconv branch (withDarwinIconv → Apple libiconv), which also
          # puts Apple's iconv.h ahead of GNU's on the include path — so whois's own
          # simple_recode.c compiles against plain iconv(). That splits the binary
          # across two libiconvs (Apple for whois, GNU for libunistring), and linking
          # both collides on the _libiconv_version symbol they each define.
          #
          # Fix: make the ENTIRE binary use one libiconv, GNU's. -D-rename whois's own
          # iconv calls to libiconv() (preprocessor, so it does not depend on which
          # iconv.h wins the include search — the `iconv_t` typedef stays Apple's
          # void*, ABI-compatible with GNU's), and link GNU's static libiconv.a +
          # libcharset.a by absolute path (last on the link = correct static order
          # after -lunistring). LDFLAGS `-L` puts GNU ahead of withDarwinIconv's
          # appended Apple `-liconv`, so nothing resolves to Apple and citrus_iconv.c.o
          # (which carries the duplicate _libiconv_version) is never pulled.
          # Functionally identical — GNU libiconv does the same charset conversion.
          # makeFlagsArray, not makeFlags, because the values contain spaces.
          preBuild = (oa.preBuild or "") + lib.optionalString isDarwin ''
            makeFlagsArray+=(
              "CFLAGS=-g -O2 -Diconv=libiconv -Diconv_open=libiconv_open -Diconv_close=libiconv_close -I${gnuIconv}/include"
              "LDFLAGS=-L${gnuIconv}/lib"
              "LIBS=${gnuIconv}/lib/libiconv.a ${gnuIconv}/lib/libcharset.a"
            )
          '';
        });
      windowsBuild = import ./cosmo.nix { inherit unpins-lib; };
    };
}
