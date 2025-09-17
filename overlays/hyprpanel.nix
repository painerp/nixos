{ }:

final: prev: rec {
  hyprpanel = prev.hyprpanel.overrideAttrs (oldAttrs: rec {
    src = final.fetchFromGitHub {
      owner = "painerp";
      repo = "HyprPanel";
      rev = "36cef5d017dc2d05625eec6e2599c89bfe8ea711";
      hash = "sha256-84cEpnQAOiV2NVaeWVOl5hyD3I6iRUny7UxcyK2ikmE=";
    };
  });
}
