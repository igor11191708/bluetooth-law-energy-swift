//
//  PeripheralDelegateHandler.swift
//
//
//  Created by Igor on 15.07.24.
//

import Foundation
import CoreBluetooth

extension BluetoothLEManager {
    
    // Class to handle CB Peripheral Delegate
    public class PeripheralDelegate: NSObject, CBPeripheralDelegate {
        
        /// Continuation to manage the async response for discovering services
        private var continuation: CheckedContinuation<[CBService], Error>?
       
        private var expired = Atomic<Bool>(false)

        func setExpired() {
            expired.value = true
        }

        var isExpired: Bool {
            return expired.value
        }
        
        /// Called when the peripheral discovers services
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance that discovered services
        ///   - error: An optional error if the discovery failed
        public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
           // guard isExpired else{ return }
                    
            if let error = error {
                continuation?.resume(throwing: error)
            } else if let services = peripheral.services {
                continuation?.resume(returning: services)
            }
            
            continuation = nil
        }
        
        func runTimeout(for peripheral: CBPeripheral) async{
            try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            setExpired()
            continuation?.resume(throwing: Errors.timeoutServices(peripheral))
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
                
                Task{ [weak self] in
                    await self?.runTimeout(for: peripheral)
                }
            }
        }
        
        /// Discovers services on the specified peripheral.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance on which to discover services
        /// - Returns: An array of `CBService` representing the services supported by the peripheral
        /// - Throws: An error if service discovery fails
        public static func discoverServices(for peripheral: CBPeripheral) async throws -> [CBService] {
       
            let delegate = PeripheralDelegate()
                peripheral.delegate = delegate
            let services = try await delegate.fetchServices(for: peripheral)
            peripheral.delegate = nil // Remove the delegate to prevent further callbacks
            return services
        }
        
        public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {

        }
    }
}

fileprivate final class Atomic<Value> {
    private var lock = os_unfair_lock()
    private var _value: Value

    public init(_ value: Value) {
        self._value = value
    }

    public var value: Value {
        get {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return _value
        }
        set {
            os_unfair_lock_lock(&lock)
            _value = newValue
            os_unfair_lock_unlock(&lock)
        }
    }
}
