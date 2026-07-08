# Bluetooth Library Decision

## Decision

Use project-owned interfaces first:

- `BluetoothTransport`
- `ScaleAdapter`
- `BluetoothScaleAdapter`
- `ScalePacketBuffer`
- `ScaleParsingProfile`

For physical Android scale integration, the preferred first candidate is a Classic Bluetooth SPP package such as `flutter_bluetooth_classic_serial`, because most industrial weighing indicators expose a serial byte stream over Bluetooth Classic SPP rather than BLE GATT.

Do not use a BLE-only package for Classic SPP scales.

## Why

Industrial indicators usually send continuous ASCII serial frames such as:

```text
ST,GS,+0012.340kg
```

That requires:

- paired-device discovery or selection
- RFCOMM/SPP serial stream access
- continuous byte chunks
- packet buffering
- reconnect support
- Android 12+ Bluetooth permission handling

BLE packages such as `flutter_blue_plus` are suitable only when the scale exposes a BLE GATT service/characteristic. They do not provide Classic SPP transport.

## Package evaluation summary

| Option | Transport | Fit |
| --- | --- | --- |
| `flutter_bluetooth_classic_serial` | Bluetooth Classic SPP | Best current candidate for serial weighing indicators |
| `flutter_blue_plus` | BLE GATT | Good for BLE scales only, not SPP |
| `flutter_bluetooth_serial` | Bluetooth Classic SPP | Historically common, but maintenance/current Gradle compatibility must be verified before production use |
| Vendor SDK through MethodChannel | Vendor-specific | Use when the selected scale brand requires a proprietary Android SDK |

## Current implementation

The app includes a package-neutral Bluetooth proof-of-concept transport:

- `InMemoryBluetoothTransport`
- `BluetoothScaleAdapter`
- raw byte stream parsing
- partial packet buffering
- scale diagnostics screen

This proves the app architecture handles raw byte streams without coupling UI code to a Bluetooth plugin.

## Hardware verification checklist

Before enabling physical Bluetooth in production:

1. Confirm the scale transport: Classic SPP, BLE GATT, or vendor SDK.
2. Test Android 12, 13, 14, 15 and 16 Bluetooth permissions.
3. Confirm paired-device listing.
4. Confirm continuous stream stability for at least 8 hours.
5. Confirm reconnect after app pause/resume.
6. Confirm duplicate connection prevention.
7. Capture 20+ raw packet samples and create a tenant scale profile.

