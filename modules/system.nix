{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
    auto-optimise-store = true;
  };
  console.keyMap = "de";
  time.timeZone = "Europe/Berlin";
  system.stateVersion = "24.05";
}
