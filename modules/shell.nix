{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    fishPlugins.done
    fishPlugins.puffer
    fishPlugins.pisces
  ];
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  environment.shells = [ pkgs.fish ];
}
