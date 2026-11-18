{ osConfig, lib, ... }:
let
  inherit (lib.generators) mkLuaInline;
  cfg = osConfig.modules.hyprland;

  splitTrim = sep: str: builtins.map lib.trim (lib.splitString sep str);

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

  baseByWorkspace = lib.listToAttrs (builtins.map (r: lib.nameValuePair r.workspace r) baseRules);
  customByWorkspace = lib.mapAttrs (
    name: ws: { workspace = name; } // builtins.removeAttrs ws [ "openWhenEmpty" ]
  ) cfg.workspaces;

  # Custom attributes win over the round-robin base rule for the same workspace.
  workspaceRules = builtins.attrValues (lib.recursiveUpdate baseByWorkspace customByWorkspace);

  openWhenEmpty = name: cmd: {
    _args = [
      "workspace.created"
      (mkLuaInline ''
        function(ws)
          if ws.name == "${lib.removePrefix "name:" name}" and ws.is_empty then
            hl.exec_cmd([[${cmd}]], { workspace = "${name}" })
          end
        end'')
    ];
  };
in
{
  wayland.windowManager.hyprland.settings = {
    monitor = monitors;
    workspace_rule = workspaceRules;
    on = lib.mapAttrsToList (name: ws: openWhenEmpty name ws.openWhenEmpty) (
      lib.filterAttrs (_: ws: ws.openWhenEmpty != null) cfg.workspaces
    );
  };
}
