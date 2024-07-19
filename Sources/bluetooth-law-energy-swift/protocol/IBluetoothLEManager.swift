//
//  IBluetoothLEManager.swift
//
//
//  Created by Igor  on 16.07.24.
//

import Foundation
import Combine
import CoreBluetooth

@available(macOS 11, iOS 14, tvOS 15.0, watchOS 8.0, *)
public protocol IBluetoothLEManager {
    
    /// A typealias for the state publisher.
    typealias StatePublisher = AnyPublisher<CBManagerState, Never>
    
    /// A typealias for the peripheral publisher.
    typealias PeripheralPublisher = AnyPublisher<[CBPeripheral], Never>
    
    /// A property to indicate if Bluetooth is authorized.
    var isAuthorized: Bool { get set }
    
    /// A property to indicate if Bluetooth is powered on.
    var isPowered: Bool { get set }
    
    /// A property to indicate if scanning for peripherals is ongoing.
    var isScanning: Bool { get set }
    
    /// Provides an asynchronous stream of discovered Bluetooth peripherals.
    var peripheralsStream: AsyncStream<[CBPeripheral]> { get }
    
    /// Discovers services for a given peripheral.
    ///
    /// - Parameter peripheral: The `CBPeripheral` instance for which to discover services.
    /// - Returns: An array of `CBService` representing the services supported by the peripheral.
    /// - Throws: A `BluetoothLEManager.Errors` error if service discovery fails or the peripheral is already connected.
    func discoverServices(for peripheral: CBPeripheral) async throws -> [CBService]
}
