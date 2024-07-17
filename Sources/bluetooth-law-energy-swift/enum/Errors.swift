//
//  Errors.swift
//
//
//  Created by Igor  on 15.07.24.
//

import CoreBluetooth

public extension BluetoothLEManager {
    
    enum Errors: Error, LocalizedError {
        
        /// Error encountered while discovering services.
        case discoveringServicesError(String)
        
        /// Error encountered while connecting.
        case connection(CBPeripheral, Error?)
        
        /// Error encountered while disconnecting.
        case disconnection(CBPeripheral, Error?)
        
        /// Error when peripheral is already connected.
        case connected(CBPeripheral)
        
        /// Error when peripheral is currently connecting.
        case connecting(CBPeripheral)
        
        /// Error when an operation times out.
        case timeout(CBPeripheral)
        
        public var errorDescription: String? {
            switch self {
            case .discoveringServicesError(let message):
                return NSLocalizedString("Error discovering services: \(message)", comment: "Discovering Services Error")
            case .connection(let peripheral, let error):
                return NSLocalizedString("Error connecting to \(peripheral.name ?? "unknown peripheral"): \(error?.localizedDescription ?? "unknown error")", comment: "Connection Error")
            case .disconnection(let peripheral, let error):
                return NSLocalizedString("Error disconnecting from \(peripheral.name ?? "unknown peripheral"): \(error?.localizedDescription ?? "unknown error")", comment: "Disconnection Error")
            case .connected(let peripheral):
                return NSLocalizedString("The peripheral \(peripheral.name ?? "unknown peripheral") is already connected. Please disconnect and try again.", comment: "Already Connected Error")
            case .connecting(let peripheral):
                return NSLocalizedString("The peripheral \(peripheral.name ?? "unknown peripheral") is currently connecting. Please wait until the connection is complete.", comment: "Connecting Error")
            case .timeout(let peripheral):
                return NSLocalizedString("Operation timed out for peripheral \(peripheral.name ?? "unknown peripheral").", comment: "Timeout Error")
            }
        }
    }
}
