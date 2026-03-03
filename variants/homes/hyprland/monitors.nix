{ osConfig, lib, ... }:
let
  cfg = osConfig.modules.hyprland;

  # Extract physical monitors (exclude default rules starting with comma)
  physicalMonitors = builtins.filter (m: builtins.substring 0 1 m != ",") cfg.monitors;

  # Extract monitor names (first part before comma)
  monitors = builtins.map (m: builtins.head (lib.splitString "," m)) physicalMonitors;

  monitorCount = builtins.length monitors;

  # Generate base workspace assignments (1-10)
  baseWorkspaces =
    if monitorCount == 0 then
      [ ]
    else
      builtins.genList (
        i:
        let
          workspaceNum = i + 1;
          monitorIndex = lib.mod i monitorCount;
          monitorName = builtins.elemAt monitors monitorIndex;
          isFirstOnMonitor = workspaceNum <= monitorCount;
          defaultFlag = if isFirstOnMonitor then ", default: true" else "";
        in
        "${toString workspaceNum}, monitor:${monitorName}${defaultFlag}"
      ) 10;

  # Process custom workspace rules
  processCustomRule =
    rule:
    let
      # Check if rule already contains "monitor:"
      hasMonitor = builtins.match ".*monitor:.*" rule != null;
    in
    if hasMonitor then
      rule
    else
      let
        # Extract workspace number (first number before comma)
        parts = lib.splitString "," rule;
        workspaceNumStr = lib.trim (builtins.head parts);
        workspaceNum = lib.toInt workspaceNumStr;
      in
      # Only auto-assign monitor for workspaces 1-10
      if workspaceNum >= 1 && workspaceNum <= 10 then
        let
          monitorIndex = lib.mod (workspaceNum - 1) monitorCount;
          monitorName = builtins.elemAt monitors monitorIndex;
        in
        "${rule}, monitor:${monitorName}"
      else
        rule;

  customWorkspaces = builtins.map processCustomRule cfg.workspaces.custom;

  # Create map of workspace number to rule for merging
  # Custom rules override base rules
  baseMap = builtins.listToAttrs (
    builtins.map (
      rule:
      let
        parts = lib.splitString "," rule;
        num = lib.trim (builtins.head parts);
      in
      {
        name = num;
        value = rule;
      }
    ) baseWorkspaces
  );

  customMap = builtins.listToAttrs (
    builtins.map (
      rule:
      let
        parts = lib.splitString "," rule;
        num = lib.trim (builtins.head parts);
      in
      {
        name = num;
        value = rule;
      }
    ) customWorkspaces
  );

  # Merge maps (custom overrides base)
  mergedMap = baseMap // customMap;

  # Convert back to list and sort by workspace number
  workspaceRules = builtins.map (name: mergedMap.${name}) (
    builtins.sort (a: b: (lib.toInt a) < (lib.toInt b)) (builtins.attrNames mergedMap)
  );

in
{
  wayland.windowManager.hyprland.settings = {
    monitor = cfg.monitors;
    workspace = workspaceRules;
  };
}
