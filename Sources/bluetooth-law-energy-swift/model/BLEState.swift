//
//  BLEState.swift
//
//
//  Created by Igor  on 19.07.24.
//

import Foundation

@available(macOS 12, iOS 15, tvOS 15.0, watchOS 8.0, *)
public struct BLEState {
    
    /// Indicates if Bluetooth is authorized.
    public let isAuthorized: Bool
    
    /// Indicates if Bluetooth is powered on.
    public let isPowered: Bool
    
    /// Indicates if Bluetooth is currently scanning for peripherals.
    public let isScanning: Bool
    
    /// Initializes a new `BLEState` instance.
    ///
    /// - Parameters:
    ///   - isAuthorized: A boolean indicating if Bluetooth is authorized (default is `false`).
    ///   - isPowered: A boolean indicating if Bluetooth is powered on (default is `false`).
    ///   - isScanning: A boolean indicating if Bluetooth is scanning (default is `false`).
    public init(isAuthorized: Bool = false, isPowered: Bool = false, isScanning: Bool = false) {
        self.isAuthorized = isAuthorized
        self.isPowered = isPowered
        self.isScanning = isScanning
    }
}
