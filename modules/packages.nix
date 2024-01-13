{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    nano
    dig
    htop
    git
    home-manager
    ncdu
  ];
}