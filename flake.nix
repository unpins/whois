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
      build = pkgs: pkgs.pkgsStatic.whois.overrideAttrs (oa: {
        patches = (oa.patches or [ ]) ++ [ ./whois-portability.patch ];
      });
      windowsBuild = import ./cosmo.nix { inherit unpins-lib; };
    };
}
