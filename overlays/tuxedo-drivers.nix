{ }:

final: prev: rec {
  linuxPackages_testing = prev.linuxPackages_testing.extend (
    linuxFinal: linuxPrev: {
      tuxedo-drivers = linuxPrev.tuxedo-drivers.overrideAttrs (
        oldAttrs:
        let
          version = "4.15.4";
        in
        {
          inherit version;
          src = final.fetchFromGitLab {
            group = "tuxedocomputers";
            owner = "development/packages";
            repo = "tuxedo-drivers";
            rev = "v${version}";
            hash = "sha256-WJeju+czbCw03ALW7yzGAFENCEAvDdKqHvedchd7NVY=";
          };
          postPatch = ''
            sed -i 's|cp -r etc usr /||' Makefile
          '';
        }
      );
    }
  );
}
