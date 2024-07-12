//
//  BluetoothDelegateHandler.swift
//
//
//  Created by Igor  on 12.07.24.
//

import Combine
import CoreBluetooth

extension BluetoothManager{
    
     class BluetoothDelegateHandler: NSObject, CBCentralManagerDelegate {
        let stateSubject = PassthroughSubject<CBManagerState, Never>()
        let peripheralSubject = CurrentValueSubject<[CBPeripheral], Never>([])
        
        public func centralManagerDidUpdateState(_ central: CBCentralManager) {
            stateSubject.send(central.state) // Send state updates through the subject
        }
        
        public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            var peripherals = peripheralSubject.value
            if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                peripherals.append(peripheral)
                peripheralSubject.send(peripherals)
            }
        }
    }
}
