{
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "daily";
    randomizedDelaySec = "60min";
    options = "--delete-older-than 30d";
  };
}
