{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    micro
  ];
  environment.variables.EDITOR = "micro";
}