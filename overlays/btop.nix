{ config }:

final: prev: rec {
  btop = prev.btop.override {
    rocmSupport = config.modules.amd.enable;
    cudaSupport = config.modules.nvidia.enable;
  };
}
