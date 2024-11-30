{ }:

final: prev: rec {
  teamspeak_client = prev.teamspeak_client.overrideAttrs (oldAttrs: rec {
    soundpack = final.fetchzip {
      name = "Teamspeak_DukeNukem_Soundpack";
      url = "https://addons-content.teamspeak.com/8a9a93a7-5dd6-403e-8d15-435e5bfbd970/files/3/dukenukem-2.0.0.ts3_soundpack";
      hash = "sha256-tArylFzkMgb7u2oSmEzxsongWyxBfIjkzqNqiYFd+LQ=";
      extension = "zip";
      stripRoot = false;
    };
    iconpack = final.fetchzip {
      name = "Teamspeak_DarkenTS_Icons";
      url = "https://addons-content.teamspeak.com/0b57d54d-b46c-433d-8f7e-2eea28470007/files/8/DarkenTS_v1.7.1.ts3_iconpack";
      hash = "sha256-nWdULV+oY7/XbA3lArPPKu0woe18aE/McmcI5DPfTL8=";
      extension = "zip";
      stripRoot = false;
    };
    style = final.fetchzip {
      name = "Teamspeak_DarkenTS_Style";
      url = "https://addons-content.teamspeak.com/686209af-0b66-4805-b2d7-0e990f7cb9e0/files/15/DarkenTSv172_5ec97131ef925.ts3_style";
      hash = "sha256-CztGAxuE1x00Qhw38Lzasg3qyLrgpxNNKGsmWZo5U80=";
      extension = "zip";
      stripRoot = false;
    };
    installPhase =
      oldAttrs.installPhase
      + ''
        cp -r ${soundpack}/sound/dukenukem $out/opt/teamspeak/sound
        cp -r ${iconpack}/gfx/DarkenTS $out/opt/teamspeak/gfx
        cp -r ${style}/styles/* $out/opt/teamspeak/styles
      '';
  });
}
