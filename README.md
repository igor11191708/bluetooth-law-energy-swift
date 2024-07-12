# Bluetooth Low Energy Service

## Description

`BluetoothLEManager` is a class for managing Bluetooth Low Energy (BLE) operations. It is designed to be used in SwiftUI applications, handling tasks such as checking Bluetooth authorization and power status, and scanning for BLE peripherals.

This manager class is `ObservableObject`, which makes it easy to integrate with SwiftUI by providing published properties for the Bluetooth state.

## SwiftUI example

For a complete example of using `BluetoothLEManager` in a SwiftUI application, please follow the [Example Project](https://example.com/repo).

## Supported Platforms

| iOS 13 | macOS 11 |
|:-------:|:-------:|
| ![iOS 13](https://github.com/The-Igor/bluetooth-law-energy-swift/blob/main/img/ble_manager.jpeg) | ![macOS 11](https://github.com/The-Igor/bluetooth-law-energy-swift/blob/main/img/bluetoth_le.gif) |

## Bluetooth LE Manager Implementation Specifics

`BluetoothLEManager` serves as a wrapper around `CBCentralManager`, providing a streamlined interface for managing Bluetooth Low Energy (BLE) operations. This package integrates the authorization and power state monitoring specific to Apple's implementation for BLE devices, which simplifies handling these aspects within your application.

### Key Implementation Details

1. **Authorization and Power State Management**:
   - When a `CBCentralManager` is instantiated, it automatically prompts the user for Bluetooth authorization if it hasn't been granted yet. This prompt is managed by the system, and no additional code is needed to request authorization.
   - If Bluetooth is turned off during the lifecycle of `BluetoothLEManager`, the manager will handle this state change and update the relevant properties (`isAuthorized`, `isPowered`, etc.) accordingly. This ensures that your application remains informed about the Bluetooth state throughout its lifecycle.

2. **Handling Mid-Lifecycle Bluetooth State Changes**:
   - If Bluetooth is turned off or access is denied while `BluetoothLEManager` is active, the manager will process this change and provide the necessary updates to the state properties. This allows your application to respond to changes in Bluetooth availability dynamically.

3. **User Authorization Handling**:
   - When a `CBCentralManager` is created, it prompts the user for authorization if it hasn't been granted yet. If the user denies this request, `BluetoothLEManager` will detect this and update its `isAuthorized` property accordingly.
   - If authorization is denied, the manager can inform the user and suggest that they enable Bluetooth access in the device settings. This ensures that your application can guide users to resolve authorization issues without requiring additional implementation.

4. **Dynamic Scanning Based on Subscribers**:
   - `BluetoothLEManager` manages the scanning process based on the number of active subscribers waiting the peripheral list.
   - Scanning for peripherals starts only when at least one subscriber is connected through the `peripheralsStream` method to get the list of peripherals. This ensures that scanning is active when there is a need for peripheral data.
   - When the number of subscribers drops to zero, the manager stops scanning to conserve resources and battery life. This allows efficient use of the device's Bluetooth capabilities.

## Public API

### Properties

| Type      | Name                   | Description                                          |
|-----------|------------------------|------------------------------------------------------|
| `Bool`    | `isAuthorized`         | Indicates if Bluetooth is authorized.                |
| `Bool`    | `isPowered`            | Indicates if Bluetooth is powered on.                |
| `Bool`    | `isScanning`           | Indicates if scanning for peripherals is ongoing.    |
| `StatePublisher` | `getStatePublisher`    | A publisher that emits the state of the Bluetooth manager. |
| `PeripheralPublisher` | `getPeripheralPublisher` | A publisher that emits an array of discovered peripherals. |

### Methods

| Method                        | Description                                                      |
|-------------------------------|------------------------------------------------------------------|
| `peripheralsStream`           | Provides an asynchronous stream of discovered Bluetooth peripherals. |

## Example Usage

### Simple Example

Here is a simple example of how to use `BluetoothLEManager` in a SwiftUI application:

```swift
import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothLEManager()

    var body: some View {
        VStack {
            Text(bluetoothManager.isAuthorized ? "Bluetooth Authorized" : "Bluetooth Not Authorized")
            Text(bluetoothManager.isPowered ? "Bluetooth Powered On" : "Bluetooth Powered Off")
            Text(bluetoothManager.isScanning ? "Scanning for Peripherals" : "Not Scanning")
            List {
                ForEach(bluetoothManager.getPeripheralPublisher.value, id: \.identifier) { peripheral in
                    Text(peripheral.name ?? "Unknown")
                }
            }
        }
        .onAppear {
            bluetoothManager.peripheralsStream
        }
    }
}
```

### Advanced Example

Here is an advanced example where we initialize an asynchronous stream in a task and update a state variable with the asynchronous data from this stream, which is then passed to a list:

```swift
import SwiftUI
import CoreBluetooth

struct AdvancedContentView: View {
    @StateObject private var bluetoothManager = BluetoothLEManager()
    @State private var peripherals: [CBPeripheral] = []

    var body: some View {
        VStack {
            Text(bluetoothManager.isAuthorized ? "Bluetooth Authorized" : "Bluetooth Not Authorized")
            Text(bluetoothManager.isPowered ? "Bluetooth Powered On" : "Bluetooth Powered Off")
            Text(bluetoothManager.isScanning ? "Scanning for Peripherals" : "Not Scanning")
            List {
                ForEach(peripherals, id: \.identifier) { peripheral in
                    Text(peripheral.name ?? "Unknown")
                }
            }
        }
        .task {
            for await discoveredPeripherals in bluetoothManager.peripheralsStream {
                peripherals = discoveredPeripherals
            }
        }
    }
}
```

## License

This project is licensed under the MIT License.
