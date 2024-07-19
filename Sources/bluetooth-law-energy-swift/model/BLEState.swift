//
//  BLEState.swift
//
//
//  Created by Igor  on 19.07.24.
//

import Foundation

@available(macOS 12, iOS 15, tvOS 15.0, watchOS 8.0, *)
public struct BLEState{
    
    public let isAuthorized : Bool
    
    public let isPowered : Bool
    
    public let isScanning :Bool
    
    public init(isAuthorized: Bool = false, isPowered: Bool = false, isScanning: Bool = false) {
        self.isAuthorized = isAuthorized
        self.isPowered = isPowered
        self.isScanning = isScanning
    }
}
