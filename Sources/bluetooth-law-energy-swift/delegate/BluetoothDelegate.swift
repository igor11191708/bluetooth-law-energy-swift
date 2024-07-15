//
//  BluetoothDelegateHandler.swift
//
//
//  Created by Igor on 12.07.24.
//

import Combine
import CoreBluetooth

// Extension of BluetoothLEManager to handle Bluetooth operations through a delegate.
extension BluetoothLEManager {

    /// A class that handles Bluetooth central manager delegate methods and publishes Bluetooth state and discovered peripherals.
    class BluetoothDelegate: NSObject, CBCentralManagerDelegate {
        
        /// A subject to publish Bluetooth state updates.
        private let stateSubject = PassthroughSubject<CBManagerState, Never>()
        
        /// A subject to publish discovered Bluetooth peripherals.
        private let peripheralSubject = CurrentValueSubject<[CBPeripheral], Never>([])
        
        /// A subject to publish connection results.
        private var connectSubject = PassthroughSubject<Result<CBPeripheral, BluetoothLEManager.Errors>, Never>()
        
        /// A subject to publish disconnection results.
        private var disconnectSubject = PassthroughSubject<Result<CBPeripheral, BluetoothLEManager.Errors>, Never>()
        
        /// Connects to a given peripheral.
        ///
        /// This asynchronous method attempts to connect to the peripheral using the provided CBCentralManager.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance to connect to.
        ///   - manager: The `CBCentralManager` used to manage the connection.
        /// - Returns: The connected `CBPeripheral`.
        /// - Throws: A `BluetoothLEManager.Errors` error if the connection fails.
        public func connect(to peripheral: CBPeripheral, with manager: CBCentralManager) async throws -> CBPeripheral {
            return try await withCheckedThrowingContinuation { continuation in
                var cancellable: AnyCancellable? = nil
                
                // Subscribe to the connectSubject to handle connection results
                cancellable = connectSubject
                    .eraseToAnyPublisher()
                    .sink { result in
                        cancellable?.cancel()  // Cancel the subscription right after resuming
                        switch result {
                        case .success(let connectedPeripheral):
                            continuation.resume(returning: connectedPeripheral)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                
                manager.connect(peripheral)  // Initiate connection to the peripheral
            }
        }
         
        /// Disconnects from a given peripheral.
        ///
        /// This asynchronous method attempts to disconnect from the peripheral using the provided CBCentralManager.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance to disconnect from.
        ///   - manager: The `CBCentralManager` used to manage the disconnection.
        /// - Returns: The disconnected `CBPeripheral`.
        /// - Throws: A `BluetoothLEManager.Errors` error if the disconnection fails.
        public func disconnect(from peripheral: CBPeripheral, with manager: CBCentralManager) async throws -> CBPeripheral {
            return try await withCheckedThrowingContinuation { continuation in
                var cancellable: AnyCancellable? = nil
                
                // Subscribe to the disconnectSubject to handle disconnection results
                cancellable = disconnectSubject.eraseToAnyPublisher().sink { result in
                    cancellable?.cancel()  // Cancel the subscription right after resuming
                    switch result {
                    case .success(let disconnectedPeripheral):
                        continuation.resume(returning: disconnectedPeripheral)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                manager.cancelPeripheralConnection(peripheral)  // Initiate disconnection from the peripheral
            }
        }
        
        /// A publisher for Bluetooth state updates, applying custom operators to handle initial powered-off state and receive on the main thread.
        public var statePublisher: AnyPublisher<CBManagerState, Never> {
            stateSubject
                .dropFirstIfPoweredOff()
                .receiveOnMainAndEraseToAnyPublisher()
        }
        
        /// A publisher for discovered Bluetooth peripherals, ensuring updates are received on the main thread.
        public var peripheralPublisher: AnyPublisher<[CBPeripheral], Never> {
            peripheralSubject
                .receiveOnMainAndEraseToAnyPublisher()
        }
        
        // MARK: - Delegate methods
        
        /// Called when the central manager's state is updated.
        ///
        /// - Parameter central: The central manager whose state has been updated.
        public func centralManagerDidUpdateState(_ central: CBCentralManager) {
            // Send state updates through the state subject
            stateSubject.send(central.state)
        }
        
        /// Called when a peripheral is discovered during a scan.
        ///
        /// - Parameters:
        ///   - central: The central manager that discovered the peripheral.
        ///   - peripheral: The discovered peripheral.
        ///   - advertisementData: A dictionary containing advertisement data.
        ///   - RSSI: The signal strength of the peripheral.
        public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            var peripherals = peripheralSubject.value
            // Add the peripheral to the list if it hasn't been discovered before
            if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                peripherals.append(peripheral)
                peripheralSubject.send(peripherals)
            }
        }
        
        /// Called when a connection to a peripheral is successful.
        ///
        /// - Parameters:
        ///   - central: The central manager managing the connection.
        ///   - peripheral: The peripheral that has successfully connected.
        public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            connectSubject.send(.success(peripheral))
        }
        
        /// Called when a connection attempt to a peripheral fails.
        ///
        /// - Parameters:
        ///   - central: The central manager managing the connection.
        ///   - peripheral: The peripheral that failed to connect.
        ///   - error: The error that occurred during the connection attempt.
        public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            let e = error ?? NSError(domain: "BluetoothLEManager", code: CBError.unknown.rawValue, userInfo: [NSLocalizedDescriptionKey: "Failed to connect to the peripheral."])
            connectSubject.send(.failure(.connection(peripheral, e)))
        }
        
        /// Called when a peripheral disconnects.
        ///
        /// - Parameters:
        ///   - central: The central manager managing the connection.
        ///   - peripheral: The peripheral that has disconnected.
        ///   - error: The error that occurred during the disconnection, if any.
        public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            if let error = error {
                disconnectSubject.send(.failure(.connection(peripheral, error)))
            } else {
                disconnectSubject.send(.success(peripheral))
            }
        }
    }
}
