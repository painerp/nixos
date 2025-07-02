{ }:

final: prev: rec {
  hyprpanel = prev.hyprpanel.overrideAttrs (oldAttrs: rec {
    src = final.fetchFromGitHub {
      owner = "painerp";
      repo = "HyprPanel";
      rev = "4e6337809d6f76872d1fb23f8a12a97013591fb5";
      hash = "sha256-8NUIKx8mfMscbWqeMhToDOuocXhPIjIZMvjbu3Fc1ok=";
    };
  });
}
