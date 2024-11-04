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
    audiosink = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      output = lib.mkOption {
        type = lib.types.str;
        required = cfg.audiosink.enable;
      };
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
      // lib.attrsets.optionalAttrs (cfg.audiosink.enable) {
        extraConfig.pipewire = {
          "10-null-sink"."context.objects" = [
            {
              factory = "adapter";
              args = {
                "node.name" = "null_sink";
                "media.class" = "Audio/Sink";
                "audio.position" = "FL,FR";
                "factory.name" = "support.null-audio-sink";
                "node.description" = "Null Sink";
              };
            }
          ];
          "20-combine-sink"."context.modules" = [
            {
              name = "libpipewire-module-combine-stream";
              args = {
                "node.name" = "combined_sink";
                "factory.name" = "combine-sink";
                "node.description" = "Combined Sink";
                "combine.latency-compensate" = false;
                "combine.probs" = {
                  "audio.position" = "FL,FR";
                };
                "stream.props" = {
                  stream.dont-remix = true;
                };
                "stream.rules" = [
                  {
                    matches = [ { "node.name" = "null_sink"; } ];
                    actions = {
                      create-stream = {
                        "combine.audio.position" = "FL,FR";
                        "audio.position" = "FL,FR";
                      };
                    };
                  }
                  {
                    matches = [ { "node.name" = "${cfg.audiosink.output}"; } ];
                    actions = {
                      create-stream = {
                        "combine.audio.position" = "FL,FR";
                        "audio.position" = "FL,FR";
                      };
                    };
                  }
                ];
              };
            }
          ];
        };
      };
  };
}
