//
//  CachedServices.swift
//
//
//  Created by Igor  on 19.07.24.
//

import CoreBluetooth

actor CachedServices {
    
    private var data: [UUID: [CBService]] = [:]

    func add(key: UUID, services: [CBService]) {
        data[key] = services
    }

    func remove(key: UUID) {
        data.removeValue(forKey: key)
    }
    
    func removeAll() {
        data = [:]
    }

    func fetch(for peripheral: CBPeripheral) -> [CBService]? {
        let key = peripheral.getId
        return data[key]
    }
}
