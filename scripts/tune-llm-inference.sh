#!/bin/bash
# Restore the LLM-inference tuning this box had under NixOS.
#
# Hardware: Framework Desktop, Ryzen AI Max+ 395 "Strix Halo" (gfx1151),
# 128 GiB unified LPDDR5, Radeon 8060S iGPU.
#
# The NixOS config (nix/modules/hosts/_machines/gpu_configs/amd.nix) raised the
# GTT ceiling and lifted the memlock limit. A stock CachyOS install does
# neither, which costs a large chunk of GPU-addressable memory and forces the
# model to live in pageable (and zram-compressible) memory.
#
# Run:  ./scripts/tune-llm-inference.sh
# Then: reboot (the GTT change is a kernel parameter).

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user; the script calls sudo where needed." >&2
  exit 1
fi

USER_NAME=${SUDO_USER:-$USER}

# 110 GiB expressed in 4 KiB pages. This is a ceiling, not a reservation: GTT is
# only backed by RAM as the GPU actually allocates it.
GTT_PAGES=28835840

echo "==> 1/5 GTT ceiling (kernel parameters via Limine)"
# amdgpu defaults GTT to 50% of RAM (~62.5 GiB here). RADV then exposes a Vulkan
# device-local heap of 2/3 * (VRAM carve + GTT), i.e. ~42 GiB — too small for a
# 30 GB model plus KV cache, so llama.cpp silently keeps layers on the CPU.
# Raising GTT to 110 GiB restores the ~74 GiB heap this box had under NixOS.
if grep -q 'ttm.pages_limit' /etc/default/limine; then
  echo "    already present in /etc/default/limine, skipping"
else
  sudo cp /etc/default/limine /etc/default/limine.bak.$(date +%Y%m%d%H%M%S)
  printf 'KERNEL_CMDLINE[default]+=" ttm.pages_limit=%s ttm.page_pool_size=%s"\n' \
    "$GTT_PAGES" "$GTT_PAGES" | sudo tee -a /etc/default/limine >/dev/null
  sudo limine-update
  echo "    added; takes effect after reboot"
fi

echo "==> 2/5 memlock limit"
# llama.cpp mlock()s the weights so they can never be paged or swapped out.
# CachyOS leaves RLIMIT_MEMLOCK at 8 MiB, so this fails:
#   "failed to mlock 30004072448-byte buffer: Cannot allocate memory"
sudo tee /etc/security/limits.d/99-memlock.conf >/dev/null <<'EOF'
# Unlimited memlock so llama.cpp / ROCm can pin model weights.
*    -    memlock    unlimited
root -    memlock    unlimited
EOF
sudo mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d
printf '[Manager]\nDefaultLimitMEMLOCK=infinity\n' \
  | sudo tee /etc/systemd/system.conf.d/99-memlock.conf >/dev/null
printf '[Manager]\nDefaultLimitMEMLOCK=infinity\n' \
  | sudo tee /etc/systemd/user.conf.d/99-memlock.conf >/dev/null
echo "    set; takes effect on next login"

echo "==> 3/5 swappiness"
# CachyOS ships vm.swappiness=100 with a 125 GiB zram device. That is a good
# default for a desktop, but it means an un-mlocked 30 GB model gets zstd-
# compressed into zram and decompressed on every access.
sudo tee /etc/sysctl.d/99-llm-inference.conf >/dev/null <<'EOF'
# Keep large model buffers resident instead of pushing them into zram.
vm.swappiness = 10
EOF
sudo sysctl --system >/dev/null
echo "    vm.swappiness = 10"

echo "==> 4/5 render group"
# ROCm needs /dev/kfd. CachyOS currently ships it mode 0666 so this works by
# accident; group membership is the supported path.
if id -nG "$USER_NAME" | grep -qw render; then
  echo "    $USER_NAME already in render"
else
  sudo usermod -aG render "$USER_NAME"
  echo "    added $USER_NAME to render; takes effect on next login"
fi

echo "==> 5/5 platform profile"
# The CPU and iGPU share one power budget. "balanced" caps sustained clocks.
if [[ -w /sys/firmware/acpi/platform_profile ]] || sudo test -w /sys/firmware/acpi/platform_profile; then
  echo performance | sudo tee /sys/firmware/acpi/platform_profile >/dev/null
  sudo tee /etc/systemd/system/platform-profile-performance.service >/dev/null <<'EOF'
[Unit]
Description=Set ACPI platform profile to performance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo performance > /sys/firmware/acpi/platform_profile'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl enable platform-profile-performance.service >/dev/null 2>&1 || true
  echo "    set to performance and persisted"
else
  echo "    /sys/firmware/acpi/platform_profile not writable, skipping"
fi

cat <<'EOF'

Done. Reboot, then verify:

  cat /sys/class/drm/card1/device/mem_info_gtt_total   # expect ~112 GiB
  vulkaninfo | grep -A2 DEVICE_LOCAL                   # expect ~74 GiB heap
  ulimit -l                                            # expect "unlimited"
  id -nG | tr ' ' '\n' | grep render                   # expect "render"

Then, in LM Studio, switch the runtime from Vulkan to ROCm:
  Settings -> Runtimes -> GGUF -> "ROCm llama.cpp (Linux)"
The bundled ROCm runtime lists gfx1151 as a supported target and is not subject
to the RADV 2/3-of-pool cap.
EOF
