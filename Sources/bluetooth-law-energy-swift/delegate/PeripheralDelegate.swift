//
//  PeripheralDelegateHandler.swift
//
//
//  Created by Igor  on 15.07.24.
//

import CoreBluetooth

extension BluetoothLEManager {
    
    // Class to handle CB Peripheral Delegate
    class PeripheralDelegate: NSObject, CBPeripheralDelegate {
        
        /// Continuation to manage the async response for discovering services
        private var continuation: CheckedContinuation<[CBService], Error>?

        /// Called when the peripheral discovers services
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance that discovered services
        ///   - error: An optional error if the discovery failed
        public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

            if let error = error {
                continuation?.resume(throwing: error)
            } else if let services = peripheral.services {
                continuation?.resume(returning: services)
            }
            
            // Clear the continuation to avoid retaining it
            continuation = nil
        }

        /// Initiates the discovery of services on the specified peripheral
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance on which to discover services
        /// - Returns: An array of `CBService` representing the services supported by the peripheral
        /// - Throws: An error if service discovery fails
        public func fetchServices(for peripheral: CBPeripheral) async throws -> [CBService] {
            return try await withCheckedThrowingContinuation { cont in
                continuation = cont
                peripheral.discoverServices(nil)
            }
        }
        
        /// Checks if the given peripheral is connected.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check the connection status of.
        ///
        /// - Throws: `BluetoothLEManager.Errors.alreadyConnected` if the peripheral is connected.
        ///
        /// - Note: This function does not perform any actions if the peripheral is not connected.
        public static func checkIfConnected(for peripheral: CBPeripheral) throws {
            if peripheral.state == .connected {
                throw BluetoothLEManager.Errors.alreadyConnected(peripheral)
            }
        }
        
        /// Discovers services for the specified peripheral.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance for which to discover services.
        ///
        /// - Returns: An array of `CBService` objects representing the services discovered on the peripheral.
        ///
        /// - Throws: An error if the service discovery process fails.
        public static func discoverServices(for peripheral: CBPeripheral) async throws -> [CBService] {
            let delegate = PeripheralDelegate()
            peripheral.delegate = delegate
            let services = try await delegate.fetchServices(for: peripheral)
            peripheral.delegate = nil // Remove the delegate to prevent further callbacks
            return services
        }
    }
}
