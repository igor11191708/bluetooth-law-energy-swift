# Bluetooth Low Energy Kit 
## Leveraging swift new concurrency model

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FThe-Igor%2Fbluetooth-law-energy-swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/The-Igor/bluetooth-law-energy-swift) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FThe-Igor%2Fbluetooth-law-energy-swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/The-Igor/bluetooth-law-energy-swift)

## SwiftUI example

For an example of using `BluetoothLEManager` in a SwiftUI application, please follow the link [swiftui example](https://github.com/The-Igor/bluetooth-law-energy_example).

![macOS 11](https://github.com/The-Igor/bluetooth-law-energy-swift/blob/main/img/ble_mac.png) 

## Main Features 

- **Bluetooth Authorization Management**
- **Bluetooth Power Management**
- **State Publishing**
- **User Interface Integration**
- **Peripheral Management**
- **Multi-platform**
- **Utilizing modern concurrency in Swift with Async stream**
- **Scanning of available devices**
- **Fetching services for discovered devices asynchronously** (the example is coming)

 <img src="https://github.com/The-Igor/bluetooth-law-energy-swift/blob/main/img/ble_manager.jpeg" alt="macOS 11" style="height: 780px;"> 
 
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
5. **Specifics of Authorizing Access to Bluetooth and Checking Availability for macOS**:
   - Detailed guidance on these aspects can be found [here](https://github.com/The-Igor/bluetooth-law-energy_example).
   
## Public API

| Name                     | Type       | Description                                                                                          | Type/Return Type                                  |
|--------------------------|------------|------------------------------------------------------------------------------------------------------|--------------------------------------------------|
| `bleState`               | Property   | A subject that publishes the BLE state changes.                                                      | `CurrentValueSubject<BLEState, Never>`           |
| `peripheralsStream`      | Property   | Provides an asynchronous stream of discovered Bluetooth peripherals.                                  | `AsyncStream<[CBPeripheral]>`                    |
| `fetchServices`          | Method     | Fetches services for a given peripheral, with optional caching.                                       | `async throws -> [CBService]`                    |


### BLEState

The `BLEState` struct provides information about the current state of Bluetooth on the device. This struct includes three key properties that indicate whether Bluetooth is authorized, powered on, and actively scanning for peripherals.

#### Properties

| Name           | Type   | Description                                                                 |
|----------------|--------|-----------------------------------------------------------------------------|
| `isAuthorized` | Bool   | Indicates if Bluetooth is authorized (`true` if authorized, `false` otherwise). |
| `isPowered`    | Bool   | Indicates if Bluetooth is powered on (`true` if powered, `false` otherwise). |
| `isScanning`   | Bool   | Indicates if Bluetooth is currently scanning for peripherals (`true` if scanning, `false` otherwise). |


### Description of `IBluetoothLEManager` Protocol

The `IBluetoothLEManager` protocol defines the essential functionalities for managing Bluetooth Low Energy (BLE) operations. It includes properties and methods for monitoring the state of Bluetooth, discovering peripherals, and fetching services for a specific peripheral. This protocol is intended to be implemented by classes or structures that handle Bluetooth communication in a macOS, iOS, tvOS, or watchOS environment.

## License

This project is licensed under the MIT License.
