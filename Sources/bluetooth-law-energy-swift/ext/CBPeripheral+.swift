//
//  CBPeripheral+.swift
//
//
//  Created by Igor  on 19.07.24.
//

import CoreBluetooth

public extension CBPeripheral{
    
    var isConnected : Bool{
        self.state == .connected
    }
    
    var isNotConnected : Bool{
        self.state != .connected
    }
    
    var getId: UUID {
        return self.identifier
    }
    
    var getName : String{
        name ?? "unknown"
    }
}
