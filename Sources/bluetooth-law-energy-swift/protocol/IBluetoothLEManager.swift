//
//  IBluetoothLEManager.swift
//
//
//  Created by Igor on 16.07.24.
//

import Foundation
import Combine
import CoreBluetooth

@available(macOS 12, iOS 15, tvOS 15.0, watchOS 8.0, *)
/// A protocol defining the Bluetooth LE manager functionality.
public protocol IBluetoothLEManager {

    /// A subject that publishes the BLE state changes.
    @MainActor
    var bleState: CurrentValueSubject<BLEState, Never> { get }

    /// Provides an asynchronous stream of discovered Bluetooth peripherals.
    @MainActor
    var peripheralsStream: AsyncStream<[CBPeripheral]> { get }

    /// Fetches services for a given peripheral, with optional caching and optional disconnection.
    /// Apple’s documentation specifies that all Core Bluetooth interactions should be performed on the main thread to maintain thread safety and proper synchronization of Bluetooth events.
    /// This includes interactions with CBCentralManager, such as connecting and disconnecting peripherals.
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` instance to fetch services for.
    ///   - cache: A Boolean value indicating whether to use cached data.
    ///   - disconnect: A Boolean value indicating whether to disconnect from the peripheral after fetching services.
    /// - Returns: An array of `CBService` instances.
    /// - Throws: An error if the services could not be fetched.
    @MainActor
    func discoverServices(for peripheral: CBPeripheral, cache: Bool, disconnect: Bool) async throws -> [CBService]

    /// Connects to a specific peripheral.
    /// Always use the same CBCentralManager instance to manage connections and disconnections for a peripheral to avoid errors and ensure correct behavior.
    /// - Parameter peripheral: The `CBPeripheral` instance to connect to.
    /// - Throws: `BluetoothLEManager.Errors` if the connection fails.
    @MainActor
    func connect(to peripheral: CBPeripheral) async throws

    /// Disconnects from a specific peripheral.
    /// Always use the same CBCentralManager instance to manage connections and disconnections for a peripheral to avoid errors and ensure correct behavior.
    /// - Parameter peripheral: The `CBPeripheral` instance to disconnect from.
    /// - Throws: `BluetoothLEManager.Errors` if the disconnection fails.
    @MainActor
    func disconnect(from peripheral: CBPeripheral) async throws
}
