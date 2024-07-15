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
            
            // Remove the delegate to prevent further callbacks
            peripheral.delegate = nil
            
            // Resume the continuation with either the discovered services or an error
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
        public func discoverServices(on peripheral: CBPeripheral) async throws -> [CBService] {
            return try await withCheckedThrowingContinuation { cont in
                continuation = cont
                peripheral.discoverServices(nil)
            }
        }
        
        /// Checks if the peripheral already has services or is connected
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check
        /// - Returns: An array of `CBService` representing the services supported by the peripheral if already discovered
        /// - Throws: An error if the peripheral is already connected
        static func checkPeripheralServices(for peripheral: CBPeripheral) throws -> [CBService] {
            if let services = peripheral.services {
                return services
            } else if peripheral.state == .connected {
                throw BluetoothLEManager.Errors.alreadyConnected(peripheral)
            } else {
                return []
            }
        }
    }
}
