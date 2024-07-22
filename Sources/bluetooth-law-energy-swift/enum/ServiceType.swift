//
//  ServiceType.swift
//
//
//  Created by Igor on 22.07.24.
//

import Foundation

extension BluetoothLEManager {
    
    /// An enumeration representing the different types of services.
    enum ServiceType: String {
        /// The service type for connecting to a peripheral.
        case connection = "Connecting to"
        /// The service type for disconnecting from a peripheral.
        case disconnection = "Disconnecting from"
        /// The service type for discovering services or characteristics for a peripheral.
        case discovering = "Discovering for"
    }
    
}
