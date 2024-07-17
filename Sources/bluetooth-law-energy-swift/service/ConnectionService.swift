//
//  ConnectionService.swift
//
//
//  Created by Igor on 17.07.24.
//

import CoreBluetooth

extension BluetoothLEManager {
    
    actor ConnectionService {
        
        /// Type alias for the CheckedContinuation used in async connection handling.
        private typealias Promise = CheckedContinuation<CBPeripheral, Error>
        
        /// Dictionary to keep track of connecting peripherals.
        private var register: [UUID: Promise] = [:]
        
        // MARK: - Private Helper Methods
        
        /// Checks if the peripheral is not currently connecting.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check.
        /// - Returns: A boolean indicating if the peripheral is not connecting.
        private func isNotConnecting(_ peripheral: CBPeripheral) -> Bool {
            return register[peripheral.identifier] == nil
        }
        
        /// Checks if the peripheral is connected.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check.
        /// - Returns: A boolean indicating if the peripheral is connected.
        private func isConnected(_ peripheral: CBPeripheral) -> Bool {
            return peripheral.state == .connected
        }
        
        /// Checks if the peripheral is not connected.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check.
        /// - Returns: A boolean indicating if the peripheral is connected.
        private func isNotConnected(_ peripheral: CBPeripheral) -> Bool {
            !isConnected(peripheral)
        }
        
        /// Adds a connecting continuation for the peripheral.
        ///
        /// - Parameters:
        ///   - continuation: The `Promise` continuation to add.
        ///   - peripheral: The `CBPeripheral` instance to associate with the continuation.
        private func addConnecting(_ continuation: Promise, for peripheral: CBPeripheral) {
            register[peripheral.identifier] = continuation
        }
        
        /// Removes the connecting continuation for the peripheral.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance for which to remove the continuation.
        private func removeConnecting(for peripheral: CBPeripheral) {
            register.removeValue(forKey: peripheral.identifier)
        }
        
        // MARK: - Connect API
        
        /// Initiates connection to a peripheral.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance to connect.
        ///   - centralManager: The `CBCentralManager` instance to use for the connection.
        /// - Returns: The connected `CBPeripheral`.
        /// - Throws: An error if the connection fails.
        public func connect(to peripheral: CBPeripheral, using centralManager: CBCentralManager) async throws -> CBPeripheral {
            return try await withCheckedThrowingContinuation { continuation in
                
                guard isNotConnected(peripheral) else {
                    continuation.resume(throwing: Errors.connected(peripheral))
                    return
                }
                
                guard isNotConnecting(peripheral) else {
                    continuation.resume(throwing: Errors.connecting(peripheral))
                    return
                }
                
                addConnecting(continuation, for: peripheral)
                centralManager.connect(peripheral, options: nil)
            }
        }
        
        /// Handles a successful connection to a peripheral.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance that was connected.
        public func handleDidConnect(_ peripheral: CBPeripheral) {
            if let continuation = register[peripheral.identifier] {
                removeConnecting(for: peripheral)
                continuation.resume(returning: peripheral)
            }
        }
        
        /// Handles a failed connection attempt to a peripheral.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance that failed to connect.
        ///   - error: The error that occurred during the connection attempt.
        public func handleDidFailToConnect(_ peripheral: CBPeripheral, with error: Error?) {
            if let continuation = register[peripheral.identifier] {
                removeConnecting(for: peripheral)
                continuation.resume(throwing: Errors.connection(peripheral, error))
            }
        }
    }
}
