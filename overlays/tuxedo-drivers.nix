{ }:

final: prev: {
  # nixpkgs' 4.20.1 fails on kernel 7.3 (acpi_driver removed), drop once nixpkgs ships >= 4.25
  linuxPackages_latest = prev.linuxPackages_latest.extend (
    linuxFinal: linuxPrev: {
      tuxedo-drivers = linuxPrev.tuxedo-drivers.overrideAttrs (
        oldAttrs:
        let
          version = "4.25.0";
        in
        {
          inherit version;
          src = final.fetchFromGitLab {
            group = "tuxedocomputers";
            owner = "development/packages";
            repo = "tuxedo-drivers";
            rev = "v${version}";
            hash = "sha256-AER+JPl3lem1OFV51VdOZAnr3Uy1BFSpEJNrE+shYis=";
          };
          postInstall =
            builtins.replaceStrings [ "usr/lib/udev" ] [ "files/usr/lib/udev" ]
              oldAttrs.postInstall;
        }
      );
    }
  );
}
