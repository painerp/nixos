{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty = false;
  };
  console.keyMap = "de";
  time.timeZone = "Europe/Berlin";
  system.stateVersion = "24.05";
}
