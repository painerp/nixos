{ pkgs, lib, ... }:

final: prev: rec {
  teamspeak_client = prev.teamspeak_client.overrideAttrs (oldAttrs: rec {
    soundpack = lib.fetchzip {
      url = "https://addons-content.teamspeak.com/8a9a93a7-5dd6-403e-8d15-435e5bfbd970/files/3/dukenukem-2.0.0.ts3_soundpack";
      hash = "341199c11963c0773f20bbf81824d8c3e9296bf989b6657ad489f76689449941";
    };
    iconpack = lib.fetchzip {
      url = "https://addons-content.teamspeak.com/0b57d54d-b46c-433d-8f7e-2eea28470007/files/8/DarkenTS_v1.7.1.ts3_iconpack";
      hash = "9b26447f3d5bb4a54422a8c6903628cb167a02d35b2ad8a75f4090964e68ee50";
    };
    style = lib.fetchzip {
      url = "https://addons-content.teamspeak.com/686209af-0b66-4805-b2d7-0e990f7cb9e0/files/15/DarkenTSv172_5ec97131ef925.ts3_style";
      hash = "77bcaa82e01646383871c0647f4f86195b3ca0ac1d2cddae1b7f18a331601f2f";
    };
    installPhase =
      oldAttrs.installPhase
      + ''
        cp -r ${soundpack}/sound/dukenukem $out/lib/teamspeak/sound
        cp -r ${iconpack}/gfx/DarkenTS $out/lib/teamspeak/gfx
        cp -r ${style}/styles/* $out/lib/teamspeak/styles
      '';
  });
}
