//
//  DisconnectionService.swift
//
//
//  Created by Igor on 17.07.24.
//

import CoreBluetooth

extension BluetoothLEManager {
    
    actor DisconnectionService {
        
        /// Type alias for the CheckedContinuation used in async disconnection handling.
        private typealias Promise = CheckedContinuation<CBPeripheral, Error>
        
        /// Dictionary to keep track of disconnecting peripherals.
        private var register: [UUID: Promise] = [:]
        
        // MARK: - Private Helper Methods
        
        /// Checks if the peripheral is not currently disconnecting.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check.
        /// - Returns: A boolean indicating if the peripheral is not disconnecting.
        private func isNotDisconnecting(_ peripheral: CBPeripheral) -> Bool {
            return register[peripheral.identifier] == nil
        }
        
        /// Checks if the peripheral is connected.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check.
        /// - Returns: A boolean indicating if the peripheral is connected.
        private func isConnected(_ peripheral: CBPeripheral) -> Bool {
            return peripheral.state == .connected
        }
        
        /// Adds a disconnecting continuation for the peripheral.
        ///
        /// - Parameters:
        ///   - continuation: The `Promise` continuation to add.
        ///   - peripheral: The `CBPeripheral` instance to associate with the continuation.
        private func add(_ continuation: Promise, for peripheral: CBPeripheral) {
            register[peripheral.identifier] = continuation
        }
        
        /// Removes the disconnecting continuation for the peripheral.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance for which to remove the continuation.
        private func remove(for peripheral: CBPeripheral) {
            register.removeValue(forKey: peripheral.identifier)
        }
        
        // MARK: - Disconnect API
        
        /// Initiates disconnection from a peripheral.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance to disconnect.
        ///   - centralManager: The `CBCentralManager` instance to use for the disconnection.
        /// - Returns: The disconnected `CBPeripheral`.
        /// - Throws: An error if the disconnection fails.
        public func disconnect(from peripheral: CBPeripheral, using centralManager: CBCentralManager) async throws -> CBPeripheral {
            return try await withCheckedThrowingContinuation { continuation in
                
                guard isNotDisconnecting(peripheral) else {
                    continuation.resume(throwing: Errors.disconnection(peripheral, nil))
                    return
                }
                
                guard isConnected(peripheral) else {
                    continuation.resume(throwing: Errors.disconnection(peripheral, nil))
                    return
                }
                
                add(continuation, for: peripheral)
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
        
        /// Handles a successful disconnection from a peripheral.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance that was disconnected.
        ///   - error: The error that occurred during the disconnection, if any.
        public func handleDidDisconnect(_ peripheral: CBPeripheral, with error: Error?) {
            guard let continuation = register[peripheral.identifier] else {
                return
            }
            
            remove(for: peripheral)
            
            if let error = error {
                continuation.resume(throwing: Errors.connection(peripheral, error))
                return
            }
            
            continuation.resume(returning: peripheral)
            
            #if DEBUG
            print("didDisconnectPeripheral \(peripheral.name ?? "")")
            #endif
        }
    }
}
