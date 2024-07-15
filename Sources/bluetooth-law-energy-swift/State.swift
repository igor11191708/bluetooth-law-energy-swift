//
//  State.swift
//
//
//  Created by Igor  on 12.07.24.
//

import CoreBluetooth

extension BluetoothLEManager{
    
    /// A private struct that encapsulates Bluetooth-related state checks.
    struct State {
        
        /// A computed property that checks if Bluetooth is authorized.
        ///
        /// - Returns: A Boolean value indicating whether Bluetooth is authorized.
        static var isBluetoothAuthorized: Bool {
            return CBCentralManager.authorization == .allowedAlways
        }
        
        /// A function that checks if Bluetooth is powered on for a given central manager.
        ///
        /// - Parameter manager: The `CBCentralManager` instance to check the state of.
        /// - Returns: A Boolean value indicating whether Bluetooth is powered on.
        static func isBluetoothPoweredOn(for manager: CBCentralManager) -> Bool {
           return manager.state == .poweredOn
        }
    }

}
