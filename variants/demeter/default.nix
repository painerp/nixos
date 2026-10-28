{
  imports = [ ./hardware.nix ];

  system.language = "de_DE.UTF-8";
  modules = {
    auto-upgrade.enable = true;
    gnome.enable = true;
    packages = {
      desktop = true;
      office = true;
    };
  };
  cpkgs.ice-connect.enable = true;
}
