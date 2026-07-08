# Bluetooth Scale Library Decision

## Transport Identified

Industrial weighing indicators most commonly expose continuous serial output over Bluetooth Classic Serial Port Profile (SPP/RFCOMM), often through HC-05/HC-06 style modules or embedded serial Bluetooth boards. The current implementation therefore targets Bluetooth Classic SPP first.

BLE GATT is not assumed. A BLE transport can be added later behind the same `BluetoothTransport` interface if a specific scale model requires GATT services.

## Packages Evaluated

### flutter_classic_bluetooth

- Transport: Bluetooth Classic RFCOMM/SPP.
- Android support: includes Android Bluetooth Classic APIs, paired devices, discovery, RFCOMM connect, byte streams, adapter state and reconnect support.
- Android 12+: documents `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, and related permissions.
- Continuous stream: exposes incoming bytes as Dart streams.
- Licence: MIT.
- Maintenance: modern package with Dart 3 support, platform capability reporting and published package documentation.
- Replaceability: isolated behind `ClassicSppTransport`, so it can be forked or swapped.

### flutter_bluetooth_serial

- Transport: Bluetooth Classic SPP.
- Rejected because maintenance and Android 12+ compatibility are less attractive for a new production app.

### flutter_blue_plus

- Transport: BLE GATT only.
- Rejected for the default scale path because most industrial serial indicators are Bluetooth Classic SPP, not BLE.

### flutter_reactive_ble

- Transport: BLE GATT only.
- Rejected for the same reason as `flutter_blue_plus`.

## Selected Package

`flutter_classic_bluetooth`

## Selection Reason

It directly supports the likely industrial scale transport: Bluetooth Classic RFCOMM/SPP. It provides paired-device listing, discovery, connect timeout support, incoming byte streams and connection-state streams. These map cleanly to the app architecture:

- `ScaleAdapter`
- `BluetoothScaleAdapter`
- `BluetoothTransport`
- `ClassicSppTransport`
- `ScalePacketBuffer`
- `ScaleReadingParser`

Only `ClassicSppTransport` imports the third-party package.

## Risks

- Physical scale verification still depends on having the actual weighing indicator hardware.
- Some indicators may use insecure RFCOMM or a non-standard service UUID; settings keep the SPP UUID default and the adapter can be extended for insecure UUID selection.
- Some scales may use BLE or a manufacturer SDK; those require a new transport implementation, not UI rewrites.

## Fallback Approach

If a client scale is BLE, add `BleGattTransport` behind `BluetoothTransport`.

If the selected package becomes unsuitable, fork or replace only `ClassicSppTransport`; parsing, stability, weighing, storage and UI remain unchanged.
