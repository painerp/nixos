{ osConfig, lib, ... }:
let
  cfg = osConfig.modules.hyprland;

  splitTrim = sep: str: builtins.map lib.trim (lib.splitString sep str);

  # Translate hyprlang property keys (with hyphens) to Lua attribute names
  # (with underscores). Also coerces a couple of known-typed values.
  luaKey = lib.replaceStrings [ "-" ] [ "_" ];

  parseValue =
    raw:
    if raw == "true" then
      true
    else if raw == "false" then
      false
    else
      raw;

  # "<num>, key:val, flag, ..." -> { workspace = "<num>"; <key> = <val>; ... }
  parseWorkspaceRule =
    rule:
    let
      parts = splitTrim "," rule;
      ws = builtins.head parts;
      props = builtins.tail parts;
      kv = lib.listToAttrs (
        builtins.map (
          p:
          let
            seg = lib.splitString ":" p;
          in
          if builtins.length seg == 1 then
            {
              name = luaKey (lib.trim (builtins.head seg));
              value = true;
            }
          else
            {
              name = luaKey (lib.trim (builtins.head seg));
              value = parseValue (lib.trim (lib.concatStringsSep ":" (builtins.tail seg)));
            }
        ) props
      );
    in
    { workspace = ws; } // kv;

  # "<output>,<mode>,<position>,<scale>[,mirror,<target>]"
  # An empty output (legacy ",preferred,auto,1,...") becomes the catch-all rule.
  parseMonitor =
    str:
    let
      parts = splitTrim "," str;
      output = builtins.elemAt parts 0;
      mode = builtins.elemAt parts 1;
      position = builtins.elemAt parts 2;
      scaleRaw = builtins.elemAt parts 3;
      scale = builtins.fromJSON scaleRaw;
      extras = lib.drop 4 parts;
      mirrorIdx = lib.lists.findFirstIndex (p: p == "mirror") null extras;
      mirror =
        if mirrorIdx != null && (builtins.length extras) > mirrorIdx + 1 then
          { mirror = builtins.elemAt extras (mirrorIdx + 1); }
        else
          { };
    in
    {
      inherit
        output
        mode
        position
        scale
        ;
    }
    // mirror;

  monitors = builtins.map parseMonitor cfg.monitors;

  # Physical monitors only (legacy catch-all entries start with ",").
  physicalNames = builtins.map (m: m.output) (builtins.filter (m: m.output != "") monitors);
  monitorCount = builtins.length physicalNames;

  # Default 1-10 round-robin assignment, marking the first workspace on each
  # monitor as the default workspace for that monitor.
  baseRules =
    if monitorCount == 0 then
      [ ]
    else
      builtins.genList (
        i:
        let
          ws = i + 1;
          monitor = builtins.elemAt physicalNames (lib.mod i monitorCount);
          isFirst = ws <= monitorCount;
        in
        {
          workspace = toString ws;
          inherit monitor;
        }
        // lib.optionalAttrs isFirst { default = true; }
      ) 10;

  customParsed = builtins.map parseWorkspaceRule cfg.workspaces.custom;

  # Auto-assign a monitor for custom workspaces 1-10 that didn't specify one.
  fillMonitor =
    rule:
    if rule ? monitor || monitorCount == 0 then
      rule
    else
      let
        n = lib.toIntBase10 rule.workspace;
      in
      if n >= 1 && n <= 10 then
        rule // { monitor = builtins.elemAt physicalNames (lib.mod (n - 1) monitorCount); }
      else
        rule;

  customRules = builtins.map fillMonitor customParsed;

  # Merge by workspace number; custom rules win, but we keep the `default` flag
  # from the base rule unless the custom one explicitly sets it.
  mergeRules =
    base: custom:
    let
      m = lib.listToAttrs (builtins.map (r: { name = r.workspace; value = r; }) base);
      withCustom = builtins.foldl' (
        acc: r:
        acc
        // {
          ${r.workspace} = (acc.${r.workspace} or { }) // r;
        }
      ) m custom;
    in
    builtins.attrValues withCustom;

  workspaceRules = mergeRules baseRules customRules;
in
{
  wayland.windowManager.hyprland.settings = {
    monitor = monitors;
    workspace_rule = workspaceRules;
  };
}
