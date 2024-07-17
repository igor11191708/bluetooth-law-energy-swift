//
//  ConnectionService.swift
//  
//
//  Created by Igor  on 17.07.24.
//

import CoreBluetooth

extension BluetoothLEManager {
    
    actor ConnectionService {
        
        /// Type alias for the CheckedContinuation used in async connection handling.
        private typealias Promise = CheckedContinuation<CBPeripheral, Error>
        
        /// Dictionaries to keep track of connecting and disconnecting peripherals.
        private var connecting: [UUID: Promise] = [:]
        private var disconnecting: [UUID: Promise] = [:]
        
        // MARK: - Private Helper Methods
        
        /// Checks if the peripheral is not currently connecting.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check.
        /// - Returns: A boolean indicating if the peripheral is not connecting.
        private func isNotConnecting(_ peripheral: CBPeripheral) -> Bool {
            return connecting[peripheral.identifier] == nil
        }
        
        /// Checks if the peripheral is not currently disconnecting.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check.
        /// - Returns: A boolean indicating if the peripheral is not disconnecting.
        private func isNotDisconnecting(_ peripheral: CBPeripheral) -> Bool {
            return disconnecting[peripheral.identifier] == nil
        }
        
        /// Checks if the peripheral is connected.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check.
        /// - Returns: A boolean indicating if the peripheral is connected.
        private func isConnected(_ peripheral: CBPeripheral) -> Bool {
            return peripheral.state == .connected
        }
        
        /// Adds a connecting continuation for the peripheral.
        ///
        /// - Parameters:
        ///   - continuation: The `Promise` continuation to add.
        ///   - peripheral: The `CBPeripheral` instance to associate with the continuation.
        private func addConnecting(_ continuation: Promise, for peripheral: CBPeripheral) {
            connecting[peripheral.identifier] = continuation
        }
        
        /// Removes the connecting continuation for the peripheral.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance for which to remove the continuation.
        private func removeConnecting(for peripheral: CBPeripheral) {
            connecting.removeValue(forKey: peripheral.identifier)
        }
        
        /// Adds a disconnecting continuation for the peripheral.
        ///
        /// - Parameters:
        ///   - continuation: The `Promise` continuation to add.
        ///   - peripheral: The `CBPeripheral` instance to associate with the continuation.
        private func addDisconnecting(_ continuation: Promise, for peripheral: CBPeripheral) {
            disconnecting[peripheral.identifier] = continuation
        }
        
        /// Removes the disconnecting continuation for the peripheral.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance for which to remove the continuation.
        private func removeDisconnecting(for peripheral: CBPeripheral) {
            disconnecting.removeValue(forKey: peripheral.identifier)
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
                
                guard isNotConnecting(peripheral) else {
                    continuation.resume(throwing: Errors.alreadyConnected(peripheral))
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
            if let continuation = connecting[peripheral.identifier] {
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
            if let continuation = connecting[peripheral.identifier] {
                removeConnecting(for: peripheral)
                continuation.resume(throwing: Errors.connection(peripheral, error))
            }
        }
        
        // MARK: - Disconnect API
        
        /// Initiates disconnection from a peripheral.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance to disconnect.
        ///   - centralManager: The `CBCentralManager` instance to use for the disconnection.
        /// - Returns: The disconnected `CBPeripheral`.
        /// - Throws: An error if the disconnection fails.
        public func disconnect(to peripheral: CBPeripheral, using centralManager: CBCentralManager) async throws -> CBPeripheral {
            return try await withCheckedThrowingContinuation { continuation in
                
                guard isNotDisconnecting(peripheral) else {
                    continuation.resume(throwing: Errors.disconnection(peripheral, nil))
                    return
                }
                
                guard isConnected(peripheral) else {
                    continuation.resume(throwing: Errors.disconnection(peripheral, nil))
                    return
                }
                
                addDisconnecting(continuation, for: peripheral)
                centralManager.cancelPeripheralConnection(peripheral)  // Initiate disconnection from the peripheral
            }
        }
        
        /// Handles a successful disconnection from a peripheral.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance that was disconnected.
        ///   - error: The error that occurred during the disconnection, if any.
        public func handleDidDisconnect(_ peripheral: CBPeripheral, with error: Error?) {
            guard let continuation = disconnecting[peripheral.identifier] else {
                return
            }
            
            removeDisconnecting(for: peripheral)
            
            if let error = error {
                continuation.resume(throwing: Errors.connection(peripheral, error))
                return
            }
            
            continuation.resume(returning: peripheral)
        }
    }
}
