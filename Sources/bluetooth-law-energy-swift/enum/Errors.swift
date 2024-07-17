//
//  Errors.swift
//
//
//  Created by Igor  on 15.07.24.
//

import CoreBluetooth

public extension BluetoothLEManager {
    
    enum Errors: Error, LocalizedError {
        
        case discoveringServicesError(String)  // Error encountered while discovering services
      
        case connection(CBPeripheral, Error?)  // Error encountered while connecting
       
        case disconnection(CBPeripheral, Error?) // Error encountered while disconnecting
       
        case alreadyConnected(CBPeripheral) // Error when peripheral is already connected
       
        case timeout(CBPeripheral) // Error when an operation times out
        
        public var errorDescription: String? {
            switch self {
            case .discoveringServicesError(let message):
                return NSLocalizedString("Error discovering services: \(message)", comment: "Discovering Services Error")
            case .connection(let peripheral, let error):
                return NSLocalizedString("Error connecting to \(peripheral.name ?? "unknown peripheral"): \(error?.localizedDescription)", comment: "Connection Error")
            case .disconnection(let peripheral, let error):
                return NSLocalizedString("Error disconnecting from \(peripheral.name ?? "unknown peripheral"): \(error?.localizedDescription)", comment: "Disconnection Error")
            case .alreadyConnected(let peripheral):
                return NSLocalizedString("The peripheral \(peripheral.name ?? "unknown peripheral") is already connected. Please disconnect and try again.", comment: "Already Connected Error")
            case .timeout(let peripheral):
                return NSLocalizedString("Operation timed out for peripheral \(peripheral.name ?? "unknown peripheral").", comment: "Timeout Error")
            }
        }
    }
}
