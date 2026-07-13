{ pkgs, ... }:

{
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Strix Halo shares one 128 GiB pool between CPU and iGPU. The BIOS "UMA
  # Frame Buffer / dedicated VRAM" carve (currently 96 GiB) is locked away from
  # the OS, leaving only ~31 GiB RAM (the box swaps under load). Two consequences:
  #   * RADV reports a Vulkan device-local heap of 2/3 * (VRAM carve + GTT) — why
  #     LM Studio, which is Vulkan-only for this iGPU, shows ~74 GiB not 96 GiB.
  #     Nothing on the OS side lifts that 2/3 ratio; only ROCm (llama.cpp below)
  #     addresses the full pool.
  #   * GTT (memory the GPU borrows from system RAM) defaults to 50% of RAM.
  # Raise the GTT ceiling so ROCm can spill past the BIOS carve, and so a smaller
  # carve (recommended: set BIOS UMA to 16 GiB or "Auto", then reboot) frees RAM
  # without starving the GPU. ttm.pages_limit is a ceiling, not a reservation —
  # GTT is only backed by RAM as the GPU actually allocates it.
  # 28835840 pages * 4 KiB = 110 GiB.
  boot.kernelParams = [
    "ttm.pages_limit=28835840"
    "ttm.page_pool_size=28835840"
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    # ROCm OpenCL runtime (ICD) so OpenCL workloads see the GPU.
    extraPackages = [ pkgs.rocmPackages.clr.icd ];
  };

  # ROCm userspace + tooling. This box is a Ryzen AI Max+ 395 "Strix Halo"
  # APU (gfx1151), which ROCm 6.4+/7.x supports natively — no
  # HSA_OVERRIDE_GFX_VERSION needed. If a library (e.g. rocBLAS) ever lacks
  # gfx1151 kernels, set HSA_OVERRIDE_GFX_VERSION = "11.0.0" to fall back to
  # gfx1100.
  environment.systemPackages = with pkgs.rocmPackages; [
    rocminfo # query GPU / HSA agents
    rocm-smi # monitor clocks, power, VRAM
    pkgs.clinfo # verify the OpenCL ICD

    # llama.cpp built against ROCm/HIP for gfx1151. LM Studio only ships a
    # Vulkan runtime for this iGPU (no ROCm backend in its catalog), and RADV
    # caps a Vulkan app at 2/3 of the unified pool. The ROCm/HIP backend has no
    # such cap — it sees the full 96 GiB carve (+ GTT) — so use `llama-server`
    # here for large models, e.g.:
    #   llama-server -m MODEL.gguf -ngl 999 --host 127.0.0.1 --port 1234
    (pkgs.llama-cpp.override {
      rocmSupport = true;
      rocmGpuTargets = [ "gfx1151" ];
    })
  ];

  # Access to /dev/kfd and /dev/dri for compute.
  users.users.png.extraGroups = [
    "video"
    "render"
  ];

  # Many ROCm/HIP apps hardcode ROCM_PATH=/opt/rocm. Point it at a combined
  # runtime so those apps resolve libraries and binaries.
  systemd.tmpfiles.rules =
    let
      rocmEnv = pkgs.symlinkJoin {
        name = "rocm-combined";
        paths = with pkgs.rocmPackages; [
          rocm-runtime
          clr
          rocminfo
          rocm-smi
        ];
      };
    in
    [ "L+ /opt/rocm - - - - ${rocmEnv}" ];
}
