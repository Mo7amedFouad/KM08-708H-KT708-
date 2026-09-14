# AGENTS.md — KM08-708H-KT708 (OpenWrt firmware for Mercury KM08-708H)

This repo holds build configuration only. The OpenWrt source tree is cloned
fresh by CI (`openwrt/openwrt`, branch `openwrt-24.10`); there is no local
source to compile, no tests, no linter.

## Active vs stale files

- Active CI workflow: `.github/workflows/build-kt708.yaml` (manual dispatch,
  ccache + source + `dl` caching, GitHub releases, keep-latest-5).
  `build-openwrt.yml` / `build-openwrt-template.yml` are the stale upstream
  P3TERX templates (deprecated `set-output`, no cache) — do not use or update.
- Live build config is `.config` (~7000-line expanded defconfig).
  `openwrt_km08_708h.config` is a stale minimal reference — it has
  `mercury_km08-708h` NOT set. Never copy it over `.config`.
  `.configـشه` is a stale backup duplicate — ignore it.
- `build.sh` is macOS-oriented and broken from repo root
  (`cd ./KM08-708H-KT708-` assumes a subdirectory checkout). Prefer the CI
  flow; for local builds follow `MERCURY_CONFIG_FIX.md` "Manual Build" steps.

## Build order (matters — feeds sandwich the diy scripts)

Inside a cloned `openwrt-24.10` tree, from repo root:

```sh
cp .config openwrt/.config
cp -r files/* openwrt/                      # tree overrides (DTS, mt7621.mk)
cd openwrt
../diy-part1.sh                             # adds kenzok8 kenzo/small feeds
./scripts/feeds update -a && ./scripts/feeds install -a
../diy-part2.sh                             # LAN IP, hostname
make defconfig && make download -j16 && make -j$(nproc)
```

`diy-part1.sh` must run before feed updates; `diy-part2.sh` after feed
installs. `diy-part2.sh` sets LAN `192.168.3.1` and hostname `KT708-Router`;
its wireless/network/dhcp heredocs are commented out — keep them that way
unless asked (no Wi-Fi password is configured).

## Device support layout

- Target: `ramips/mt7621`, profile `DEVICE_mercury_km08-708h`
  (MT7621AT, MT7615DN dual-band, NAND). Output:
  `bin/targets/ramips/mt7621/*mercury_km08-708h*{sysupgrade,factory}.bin`.
- `files/target/linux/ramips/` carries full-tree override copies into the
  OpenWrt tree: `dts/mt7621_mercury_km08-708h.dts`,
  `image/mt7621.mk` (device stanza `Device/mercury_km08-708h`, uImage-LZMA +
  UBI, `IMAGE_SIZE := 115712k`), `mt7621/base-files/etc/board.d/01_leds`
  (`mercury,km08-708h` case), plus `files/package/boot/uboot-envtools/`.
  These are snapshots of upstream `openwrt-24.10` files — edit surgically;
  wholesale re-copies risk silent drift from upstream.
- CI copies `files/` twice: `cp -r files/* openwrt/` (installs the tree
  overrides) and later `mv files openwrt/files` (firmware rootfs overlay).
  Keep `files/` limited to tree overrides — anything added there also lands
  in the firmware image under the same path.

## Device-tree variants (do not confuse)

- `files/target/linux/ramips/dts/mt7621_mercury_km08-708h.dts` — the one
  actually built. Proper source style (`#include "mt7621.dtsi"`).
- `mt7621_mercury_km08-708h2.dts` (repo root) — near-identical reference
  source; differs only in `bootargs` (no `ubi.mtd=...` lines).
- `mt7621_mercury_km08-708h.dts` (repo root) — decompiled full-register
  dump, wrong UART baud (`57600`), disabled `lan1`. Do not edit or promote
  into `files/`; edit the `files/` copy instead.

## Verification

```sh
./validate_config.sh   # run from repo root; greps .config
```

Must hold: `CONFIG_TARGET_ramips_mt7621_DEVICE_mercury_km08-708h=y`,
`CONFIG_TARGET_PROFILE="DEVICE_mercury_km08-708h"`, raisecom devices unset,
board `ramips` / subtarget `mt7621`. Past failure mode: `.config` pointed at
`raisecom,msg1500-x-00` while flashing a Mercury unit, producing
`Device mercury,km08-708h not supported by this image` (see
`MERCURY_CONFIG_FIX.md`). After `make defconfig`, re-grep — defconfig can
drop unknown symbols if the branch no longer carries the device.

## CI cache gotcha

Caches are keyed on `hashFiles('.config', 'diy-part1.sh')`. Config-only
changes get warm-cache incremental builds (~30 min); if a build behaves as
if the old config is in effect, re-run with the `clean_cache: true`
workflow input.
