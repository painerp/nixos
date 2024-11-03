{ config, lib, ... }:

let
  cfg = config.modules.pipewire;
in
{
  options.modules.pipewire = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    audiosink = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    services.pipewire =
      {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        #jack.enable = true;
      }
      // lib.attrsets.optionalAttrs (cfg.audiosink) {
        extraConfig.pipewire = {
          "10-null-sink".context.objects = {
            factory = "adapter";
            args = {
              node.name = "null_sink";
              media.class = "Audio/Sink";
              audio.position = [
                FL
                FR
              ];
              factory.name = "support.null-audio-sink";
              node.description = "Virtual Null Sink";
            };
          };
        };
        "20-combine-sink".context.objects = {
          factory = "adapter";
          args = {
            node.name = "combined_sink";
            media.class = "Audio/Sink";
            audio.position = [
              FL
              FR
            ];
            factory.name = "combine-sink";
            node.description = "Combined Output";
            combine.sinks = [
              { target.object = "@DEFAULT_AUDIO_SINK@"; }
              { target.object = "null_sink"; }
            ];
          };
        };
      };
  };
}
