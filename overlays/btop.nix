{ }:

final: prev: rec {
  btop_amd = prev.btop.override { rocmSupport = true; };
  btop_nvidia = prev.btop.override { cudaSupport = true; };
}
