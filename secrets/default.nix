# "cit/attic.env.age" -> cit-attic-env
builtins.listToAttrs (
  map (p: {
    name = builtins.replaceStrings [ ".age" "/" "." ] [ "" "-" "-" ] p;
    value = ./. + "/${p}";
  }) (builtins.attrNames (import ./secrets.nix))
)
