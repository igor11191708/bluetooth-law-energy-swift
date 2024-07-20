//
//  IBluetoothLEManager.swift
//
//
//  Created by Igor  on 16.07.24.
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

    /// Fetches services for a given peripheral, with optional caching.
    ///
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` instance to fetch services for.
    ///   - cache: A Boolean value indicating whether to use cached data.
    /// - Returns: An array of `CBService` instances.
    /// - Throws: An error if the services could not be fetched.
    @MainActor
    func fetchServices(for peripheral: CBPeripheral, cache: Bool) async throws -> [CBService]
}
