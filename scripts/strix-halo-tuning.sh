#!/bin/bash
# Strix Halo (Radeon 8060S / Ryzen AI Max) tuning for large-model llama.cpp inference.
# Follows https://strix-halo-toolboxes.com/#config, adapted for CachyOS + Limine.
# Idempotent: safe to re-run. Requires root. Reboot afterwards.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "error: run as root (sudo $0)" >&2
    exit 1
fi

TARGET_USER="${SUDO_USER:-png}"
MARKER="# strix-halo tuning"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
skip() { printf '    already applied: %s\n' "$1"; }


say "1/5  Kernel command line (GTT limit, TTM page limit, IOMMU off)"
# gttsize is MiB: 126976 = 124 GiB. pages_limit is 4K pages: 32505856 = 124 GiB.
# amd_iommu=off is worth 5-12% here but disables the NPU (/dev/accel/accel0)
# and DMA attack protection. Drop that token to keep the NPU.
if grep -qF "$MARKER" /etc/default/limine; then
    skip "/etc/default/limine"
else
    cp -a /etc/default/limine "/etc/default/limine.bak.$STAMP"
    cat >> /etc/default/limine <<'EOF'

# strix-halo tuning
KERNEL_CMDLINE[default]+=" amd_iommu=off amdgpu.gttsize=126976 ttm.pages_limit=32505856"
EOF
    echo "    appended; backup at /etc/default/limine.bak.$STAMP"
fi
limine-update


say "2/5  zram sized down to 16 GiB"
# CachyOS defaults zram-size to 'ram' (125 GiB). GTT pages are unswappable, so a
# zram that large competes with the 124 GiB the GPU may now claim.
mkdir -p /etc/systemd/zram-generator.conf.d
ZRAM_DROPIN=/etc/systemd/zram-generator.conf.d/99-strix-halo.conf
if [[ -f $ZRAM_DROPIN ]]; then
    skip "$ZRAM_DROPIN"
else
    cat > "$ZRAM_DROPIN" <<'EOF'
# strix-halo tuning: leave RAM headroom for GPU-pinned GTT pages.
[zram0]
zram-size = 16384
EOF
    echo "    wrote $ZRAM_DROPIN (applies on reboot)"
fi


say "3/5  GPU device permissions"
usermod -aG video,render "$TARGET_USER"
UDEV_RULE=/etc/udev/rules.d/70-kfd.rules
if [[ -f $UDEV_RULE ]]; then
    skip "$UDEV_RULE"
else
    printf 'SUBSYSTEM=="kfd", KERNEL=="kfd", MODE="0666"\nSUBSYSTEM=="drm", KERNEL=="renderD*", MODE="0666"\n' > "$UDEV_RULE"
    udevadm control --reload-rules && udevadm trigger
    echo "    wrote $UDEV_RULE"
fi


say "4/5  tuned / accelerator-performance profile"
if ! pacman -Qq tuned &>/dev/null; then
    pacman -S --needed --noconfirm tuned
fi
# tuned and power-profiles-daemon both drive the same knobs; only one may run.
if systemctl is-enabled power-profiles-daemon &>/dev/null; then
    systemctl disable --now power-profiles-daemon
    echo "    disabled power-profiles-daemon"
fi
systemctl enable --now tuned
if tuned-adm list | grep -q accelerator-performance; then
    tuned-adm profile accelerator-performance
    tuned-adm active
else
    echo "    WARNING: accelerator-performance profile not found; leaving profile unchanged" >&2
fi


say "5/5  memlock limit (not from the page - fixes the mlock error in your LM Studio log)"
# DefaultLimitMEMLOCK is 8 MiB, so llama.cpp's mlock of a 30 GB buffer always fails.
LIMIT_DROPIN=/etc/systemd/system.conf.d/99-strix-halo-memlock.conf
mkdir -p /etc/systemd/system.conf.d
if [[ -f $LIMIT_DROPIN ]]; then
    skip "$LIMIT_DROPIN"
else
    printf '[Manager]\nDefaultLimitMEMLOCK=infinity\n' > "$LIMIT_DROPIN"
    echo "    wrote $LIMIT_DROPIN (applies on reboot)"
fi


cat <<'EOF'

Done. Reboot, then verify:

  cat /proc/cmdline
  numfmt --to=iec < /sys/class/drm/card*/device/mem_info_gtt_total   # expect ~124G
  awk '{printf "%.1f GiB\n", $1*4096/1073741824}' /sys/module/ttm/parameters/pages_limit
  zramctl                                                            # expect 16G
  tuned-adm active
  ulimit -l                                                          # expect unlimited

In LM Studio, also set GPU offload to auto rather than pinning n_gpu_layers to
999999 - otherwise common_fit_params aborts instead of trimming layers to fit.
EOF
