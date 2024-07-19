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
        
       
        private let service: RegistrationService<[CBService]> = .init(type: .discovering)
       
        /// Called when the peripheral discovers services
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance that discovered services
        ///   - error: An optional error if the discovery failed
        public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
               
            Task{
            if let error = error {
                await service.handleResult(for: peripheral, result: .failure(BluetoothLEManager.Errors.discoveringServices(peripheral.getName, error)))
                
            } else if let services = peripheral.services {
                    await service.handleResult(for: peripheral, result: .success(services))
                }
            }
        }

        /// Initiates the discovery of services on the specified peripheral
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance on which to discover services
        /// - Returns: An array of `CBService` representing the services supported by the peripheral
        /// - Throws: An error if service discovery fails
        @MainActor
        public func fetchServices(for peripheral: CBPeripheral) async throws -> [CBService] {
            return try await withCheckedThrowingContinuation { continuation in
                Task{
                    let id = peripheral.getId
                    let name = peripheral.getName
                    try await service.register(to: id, name: name, with: continuation)
                    guard peripheral.isConnected else{
                        await service.handleResult(for: peripheral, result: .failure(BluetoothLEManager.Errors.discoveringServices(peripheral.getName, nil)))
                        return
                    }
                    
                    peripheral.discoverServices(nil)
                }
            }
        }
        
        public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {

        }
    }
}
