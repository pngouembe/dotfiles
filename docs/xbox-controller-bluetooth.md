# Xbox Controller over Bluetooth (png-desktop)

Pairing, diagnosing and recovering the Xbox Wireless Controller on this CachyOS box.

| | |
|---|---|
| Host | png-desktop, CachyOS, kernel 7.2.3-1-cachyos |
| BlueZ | 5.87-2.1 |
| Adapter | MediaTek MT7925 (RZ717), USB `0e8d:0717`, `hci0`, `44:F7:9F:DA:BE:2C` |
| Controller | Xbox Wireless Controller, `045E:0B13`, firmware 5.09, `A8:8C:3E:13:7A:85` |
| Transport | **BLE / HID-over-GATT** (HOGP, UUID `0x1812`) — *not* Bluetooth Classic |

The transport matters: most Xbox-on-Linux advice targets the BR/EDR path and does not apply.

Chain: `bluetoothd` reads HID descriptors over GATT -> feeds kernel via `uhid` -> kernel binds
`hid_microsoft` -> `/dev/input/js0` + an `event*` node. A break anywhere looks the same from the
desktop: pairs, shows connected, nothing responds.

## Triage

```sh
# 1 - is the link up, and is the device trusted?
bluetoothctl info A8:8C:3E:13:7A:85 | grep -E "Connected|Paired|Bonded|Trusted"

# 2 - did an input node actually appear?
ls -l /dev/input/js* ; grep -A4 "Xbox Wireless Controller" /proc/bus/input/devices

# 3 - is it stable, or reconnecting in a loop?
journalctl -u bluetooth -f | grep -vi MediaEndpoint
```

- **Healthy** — all four flags `yes`; `js0` present and *persisting*; (3) silent while idle.
- **Broken** — `Connected` flips yes/no; `js0` appears then vanishes; (3) scrolls the signature
  below every ~2s.

A present `js0` is not proof. Read the node and press buttons — the first ~23 events are an
initial-state burst emitted on open even when nothing is touched, so only events *after* it count:

```sh
timeout 15 cat /dev/input/js0 | xxd
```

## Failure signature

Repeats every ~2 seconds, forever:

```
bluetoothd: deviceinfo.c:read_pnpid_cb() Error reading PNP_ID value: Request attribute has encountered an unlikely error
bluetoothd: hog-lib.c:info_read_cb() HID Information read failed: Request attribute has encountered an unlikely error
bluetoothd: hog-lib.c:report_reference_cb() Read Report Reference descriptor failed: Request attribute has encountered an unlikely error
```

"Unlikely error" is ATT status `0x0E`, returned **by the controller**. The link establishes, then
the controller refuses to serve every HID attribute. `bluetoothd` never finishes reading the report
map, so it cannot build a usable HID device — input never flows even when the node briefly exists.

Corroborating, in `journalctl -k`:

```
# controller transmitting on a link the host already tore down
Bluetooth: hci0: ACL packet for unknown connection handle 3837

# instance number climbing fast = one re-registration per reconnect
microsoft 0005:045E:0B13.001B: input,hidraw6: BLUETOOTH HID v5.09 Gamepad
microsoft 0005:045E:0B13.001C: input,hidraw6: BLUETOOTH HID v5.09 Gamepad
```

A healthy attach registers **once** and the instance number stays put (e.g. `.0007`).

### Root cause

A **mismatched LE bond**. The host still holds pairing keys and reports `Bonded: yes`, so BlueZ
reconnects and goes straight to reading attributes without re-pairing. The controller no longer
recognises those keys — its bond slots are limited, and pairing to an Xbox, phone or another PC
evicts the oldest — so it rejects every read. Neither side renegotiates; the deadlock survives
reboots.

## Recovery: re-pair from scratch

1. **Drop the host-side bond.** Removes pairing keys and the cached GATT database under
   `/var/lib/bluetooth/`. No root needed (goes over D-Bus).

   ```sh
   bluetoothctl remove A8:8C:3E:13:7A:85
   ```

2. **Put the controller into pairing mode.** *Physical step*: hold the small **pair button** on the
   top edge next to the USB-C port ~3s, until the Xbox logo flashes **fast**. A slow blink means
   it is merely on, not pairing.

3. **Scan, pair, trust, connect.** `trust` is not optional — without it BlueZ will not auto-accept
   the controller's incoming connection on later wake-ups.

   ```sh
   bluetoothctl --timeout 15 scan on
   bluetoothctl pair    A8:8C:3E:13:7A:85
   bluetoothctl trust   A8:8C:3E:13:7A:85
   bluetoothctl connect A8:8C:3E:13:7A:85
   ```

4. **Verify it holds** for at least a minute (the fault re-appeared within seconds), then re-run the
   input test above.

   ```sh
   for i in $(seq 1 20); do
     printf "%s js0=" "$(date +%H:%M:%S)"
     [ -e /dev/input/js0 ] && echo yes || echo no
     sleep 3
   done
   ```

A helper script lives at `~/.cache/claude/repair-xbox.sh`.

## Standing configuration (did NOT fix the loop)

Applied while chasing the fault. Be clear-eyed: **these did not stop the reconnect loop** — the
signature was byte-for-byte identical before and after, across a reboot. Standard Xbox-on-Linux
hygiene, worth keeping, but do not expect them to rescue a broken bond and do not waste time
re-applying them next time.

`/etc/bluetooth/main.conf` (original backed up at `main.conf.bak`):

```ini
[General]
Class = 0x000100            # present as a computer
FastConnectable = true      # quicker page scan on reconnect
Privacy = device
JustWorksRepairing = always # accept the controller's re-pair attempts
```

`/etc/modprobe.d/bluetooth-xbox.conf`:

```
options bluetooth disable_ertm=1
```

Verify with `cat /sys/module/bluetooth/parameters/disable_ertm` (want `Y`). Takes effect only after
a reboot, since the `bluetooth` module is always in use. ERTM belongs to the Classic path, so on a
BLE-connected controller it is close to inert.

> The NixOS machine carries the same settings declaratively in
> `nix/modules/nixosModules/desktop/desktop.nix` (`hardware.bluetooth.settings` +
> `boot.extraModprobeConfig`). This box is CachyOS, so they are hand-written to `/etc`.

## Dead ends — don't re-investigate

- **Permissions.** `logind` puts an ACL for user `png` on `js0` and `event18` automatically
  (`getfacl /dev/input/event18`). No `input` group membership needed.
- **Wi-Fi / BT coexistence.** The MT7925 shares its radio, but this box is on ethernet
  (`enp191s0`) with Wi-Fi idle — no 2.4 GHz contention.
- **xpadneo.** Wrong transport: it fixes up the Bluetooth *Classic* HID path, and this controller
  is on BLE/HOGP. Not installed; installing it will not help this fault.
- **Stale input nodes.** Clean — registrations during a loop replace one another rather than
  accumulating. `grep -c "Xbox Wireless Controller" /proc/bus/input/devices` returns 1.

## If a fresh pairing still fails

Suspect the controller firmware, **5.09** here (`d0509` in `Modalias`; `BLUETOOTH HID v5.09` in the
kernel log). Microsoft shipped BLE interop fixes in later revisions; updating needs the Xbox
Accessories app on Windows or an Xbox console — no Linux path.

Before that, in order:

- Fully power-cycle the controller (hold Xbox button ~6s to power off, not just idle-sleep) and
  pair fresh.
- Fall back to **USB-C**. Wired, it enumerates as a plain USB HID gamepad and bypasses BlueZ, GATT
  and the bond entirely — fast proof that the hardware and your game's input config are fine.

## Status

- **Verified** — re-pairing ended the reconnect loop: GATT errors stopped, the controller
  registered once as instance `.0007`, and `js0` stayed present across repeated sampling (vs
  flapping every ~2s before).
- **Unverified** — whether button/stick input reaches applications. The capture after recovery
  recorded only the 23-event initial-state burst, consistent with no buttons pressed during the
  window; not evidence either way. Run the input test to close this out.
- **Untested** — whether the pairing survives reboot, controller power-cycle and suspend/resume.
  Worth checking once, since the original fault also survived a reboot.
